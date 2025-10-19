#!/usr/bin/env ucode

import * as fs from 'fs';
import { create_test_context } from '../../../helpers/mock-renderer.uc';

let test_data = json(fs.readfile("input/qos-basic.json"));
let context = create_test_context(test_data);

printf("QoS config: %J\n", context.quality_of_service);
printf("Services: %J\n", context.services);
printf("Ethernet: %J\n", context.ethernet);