# Template Testing Guide

This guide explains how to test ucode templates during refactoring to ensure they produce correct UCI output while following the new design patterns.

## Test Infrastructure Overview

The testing infrastructure has been completely refactored to provide a unified, scalable framework that eliminates code duplication and provides comprehensive test coverage across all template types.

### Key Features

- **Unified TestFramework**: Consolidated test logic eliminating ~85% code duplication
- **Import-based Architecture**: Tests are modules that export functions, enabling better integration
- **Three Template Categories**: Services, Metrics, and Base templates
- **Automatic Test Discovery**: Test runner imports and executes all test modules
- **Individual Test Counting**: Tracks total tests across all suites (currently 106 tests)
- **Simplified Test Creation**: Minimal boilerplate with helper functions

### Directory Structure

```
tests/
├── test-runner.uc                    # Master test runner (imports all test modules)
├── helpers/
│   ├── mock-renderer.uc             # Shared mock environment
│   └── test-framework.uc            # Unified test framework class
└── unit/
    ├── services/                    # Service template tests
    │   ├── ssh/
    │   │   ├── input/               # JSON test fixtures
    │   │   ├── output/              # Expected UCI outputs
    │   │   └── test-ssh.uc         # SSH test module
    │   └── [other services]/
    ├── metrics/                     # Metric template tests
    │   ├── health/
    │   │   ├── input/
    │   │   ├── output/
    │   │   └── test-health.uc
    │   └── [other metrics]/
    └── base/                        # Base template tests
        └── [base templates]/        # (interface, radio, etc.)
```

## Test Framework Architecture

### Consolidated TestFramework Class

The `TestFramework` class in `helpers/test-framework.uc` provides unified test execution:

```javascript
import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function TestFramework(template_path, test_title, test_dir) {
    return {
        template_path: template_path,    // Path to template being tested
        test_title: test_title,          // Display name for test suite
        test_dir: test_dir || ".",       // Directory containing test files
        
        run_test: function(test_name, input_file, expected_file) {
            // Loads input JSON, renders template, compares with expected output
            // Handles file generation, normalization, and reporting
        },
        
        run_tests: function(test_cases) {
            // Executes all test cases and returns aggregated results
            // Returns: { passed: N, failed: N, errors: [], suite_name: "..." }
        }
    };
}
```

### Helper Functions for Test Case Creation

Three helper functions standardize test case patterns:

```javascript
// For service templates
export function create_service_test_cases(service_name, test_names) {
    // Creates standard test case array from test names
}

// For metric templates  
export function create_metric_test_cases(metric_name, test_names) {
    // Creates standard test case array from test names
}

// For base templates
export function create_base_test_cases(template_name, test_names) {
    // Creates standard test case array from test names
}
```

### Mock Environment

The `mock-renderer.uc` provides comprehensive mocking:

- **System mocks**: `cursor`, `conn`, `fs`, `capab`, `restrict`, `default_config`
- **UCI helpers**: All `uci_*` functions with proper null handling
- **Service discovery**: Mock `services` object with lookup methods
- **Utility objects**: Mock `ethernet`, `files`, `shell` objects
- **Event mocks**: Mock events for event-based templates

## Writing Tests - New Pattern

### 1. Create Test Module (Minimal Boilerplate)

**`tests/unit/services/ssh/test-ssh.uc`**
```javascript
// SSH service template unit tests

"use strict";

import { TestFramework, create_service_test_cases } from '../../../helpers/test-framework.uc';

export function run_tests() {
    let framework = TestFramework(
        "../renderer/templates/services/ssh.uc",     // Template path
        "SSH Service Template Tests",                // Test suite name
        "unit/services/ssh"                          // Test directory
    );
    
    let test_cases = create_service_test_cases("ssh", [
        "ssh-basic",
        "ssh-restricted",
        "ssh-no-interfaces",
        "ssh-custom-port"
    ]);
    
    return framework.run_tests(test_cases);
};
```

That's it! Just 15 lines instead of ~100 lines previously needed.

### 2. Create Test Fixtures

**`tests/unit/services/ssh/input/ssh-basic.json`**
```json
{
  "uuid": "12345678-1234-1234-1234-123456789012",
  "interfaces": [
    {
      "name": "upstream",
      "role": "upstream",
      "services": ["ssh"],
      "ethernet": [{"select-ports": ["WAN"]}],
      "ipv4": {"addressing": "dynamic"}
    }
  ],
  "services": {
    "ssh": {
      "port": 22,
      "password_authentication": true,
      "idle_timeout": 300,
      "authorized_keys": ["ssh-rsa AAAAB3..."]
    }
  }
}
```

### 3. Create Expected Output

**`tests/unit/services/ssh/output/ssh-basic.uci`**
```uci
# generated by ssh.uc
### generate SSH service configuration
set dropbear.@dropbear[-1].enable=1
set dropbear.@dropbear[-1].Port='22'
set dropbear.@dropbear[-1].PasswordAuth=1
set dropbear.@dropbear[-1].IdleTimeout=300

### generate SSH firewall rules
add firewall rule
set firewall.@rule[-1].name='Allow-ssh-upstream'
set firewall.@rule[-1].src='upstream'
set firewall.@rule[-1].dest_port='22'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].target='ACCEPT'

-----/etc/dropbear/authorized_keys-----
ssh-rsa AAAAB3...
--------
```

### 4. Register in Test Runner

Add imports and test suite entry to `test-runner.uc`:

```javascript
// Import section
import { run_tests as ssh_tests } from './unit/services/ssh/test-ssh.uc';

// Test suites array
let test_suites = [
    // Services
    { name: "SSH Service", run_tests: ssh_tests },
    // ... other tests
];
```

## Test Categories

### Services (`unit/services/`)
Service-specific configurations like SSH, LLDP, mDNS, etc.
- Template location: `renderer/templates/services/`
- Helper: `create_service_test_cases()`

### Metrics (`unit/metrics/`)
Monitoring and metrics configurations like health, statistics, telemetry
- Template location: `renderer/templates/metric/`
- Helper: `create_metric_test_cases()`

### Base Templates (`unit/base/`)
Core system templates like interface, radio, switch
- Template location: `renderer/templates/`
- Helper: `create_base_test_cases()`

## Running Tests

### Execute All Tests
```bash
cd tests
ucode test-runner.uc
```

### Expected Output with New Architecture
```
=== Template Test Suite Runner ===

Found 25 test suites

=== SSH Service Template Tests ===

Running test: ssh-basic
✓ PASS: ssh-basic

Running test: ssh-restricted
✓ PASS: ssh-restricted

Running test: ssh-no-interfaces
✓ PASS: ssh-no-interfaces

Running test: ssh-custom-port
✓ PASS: ssh-custom-port

=== Test Results ===
Passed: 4
Failed: 0
All SSH Service Template Tests tests passed!

[... more test suites ...]

==================================================
=== FINAL RESULTS ===
Test suites run: 25
Suite results: 25 passed, 0 failed
Individual tests: 106 total (106 passed, 0 failed)
All test suites passed! 🎉
```

## Test Result Aggregation

The framework now provides detailed statistics:
- **Test suites run**: Total number of test modules executed
- **Suite results**: Pass/fail at the suite level
- **Individual tests**: Total count of all test cases across all suites
- **Failed suite names**: List of any suites with failures

## Common Test Patterns

### Testing Service with Multiple Scenarios
```javascript
export function run_tests() {
    let framework = TestFramework(
        "../renderer/templates/services/captive.uc",
        "Captive Service Template Tests",
        "unit/services/captive"
    );
    
    let test_cases = create_service_test_cases("captive", [
        "captive-basic",
        "captive-credentials",
        "captive-radius",
        "captive-no-service",
        "captive-no-ssids",
        "captive-multiple-interfaces",
        "captive-upstream"
    ]);
    
    return framework.run_tests(test_cases);
};
```

### Testing Metrics with Various Configurations
```javascript
export function run_tests() {
    let framework = TestFramework(
        "../renderer/templates/metric/health.uc",
        "Health Metrics Template Tests",
        "unit/metrics/health"
    );
    
    let test_cases = create_metric_test_cases("health", [
        "health-basic",
        "health-no-config",
        "health-all-disabled",
        "health-selective",
        "health-custom-interval"
    ]);
    
    return framework.run_tests(test_cases);
};
```

## File Generation Testing

Templates that generate files (like SSH authorized_keys) are automatically handled:

1. Files are captured during template rendering
2. File content is appended to UCI output with delimiters
3. Test comparison includes both UCI and file content

Example output with file:
```
# generated by ssh.uc
### generate SSH service configuration
set dropbear.@dropbear[-1].enable=1

-----/etc/dropbear/authorized_keys-----
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@example.com
--------
```

## Debugging Test Failures

### Failed Output Comparison
When tests fail, the framework shows clear diffs:
```
✗ FAIL: service-basic
Expected:
set config.param='expected'
Got:
set config.param='actual'
```

### Common Issues and Solutions

1. **Template path resolution**: Use relative paths from test directory
   - Services: `"../renderer/templates/services/[service].uc"`
   - Metrics: `"../renderer/templates/metric/[metric].uc"`
   - Base: `"../renderer/templates/[template].uc"`

2. **Whitespace differences**: Framework normalizes whitespace automatically

3. **Missing template variables**: Ensure test fixtures include all required fields

4. **File generation**: Files are automatically captured and compared

## Benefits of New Architecture

### Code Reduction
- **Before**: ~100 lines per test file × 25 tests = ~2,500 lines
- **After**: ~15 lines per test file × 25 tests = ~375 lines
- **Reduction**: ~85% less code to maintain

### Improved Maintainability
- Centralized test logic in TestFramework
- Consistent patterns across all test types
- Easy to add new test scenarios

### Better Visibility
- Individual test counting across all suites
- Clear suite-level and test-level reporting
- Aggregated statistics for overall health

### Scalability
- Simple to add new template categories
- Minimal effort to create new tests
- Automatic discovery and execution

## Adding Tests for New Templates

1. **Create directory structure**:
   ```bash
   mkdir -p tests/unit/{category}/{template}/{input,output}
   ```

2. **Create test module** using the minimal pattern shown above

3. **Add test fixtures** in `input/` directory

4. **Generate expected outputs** by running template

5. **Register in test runner**:
   - Add import statement
   - Add to test_suites array

6. **Run tests** to verify everything works

The unified framework makes adding comprehensive test coverage straightforward and maintainable.

## Test Validation Checklist

When adding tests for a template:

- [ ] **Module exports function**: Uses `export function run_tests()`
- [ ] **Uses TestFramework**: Leverages consolidated test logic
- [ ] **Appropriate helper**: Uses correct `create_*_test_cases()` function
- [ ] **Relative paths**: Template path relative from tests directory
- [ ] **Comprehensive scenarios**: Covers basic, edge cases, and errors
- [ ] **Expected outputs match**: UCI format matches actual template output
- [ ] **Registered in runner**: Import and suite entry added
- [ ] **All tests pass**: Verified with test runner

This modern testing infrastructure ensures templates maintain correctness while significantly reducing maintenance burden and improving visibility into test coverage.