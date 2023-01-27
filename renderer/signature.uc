let fs = require('fs');

let key_info = {
	'dummy_static': function(file, signature) {
		return signature == 'aaaaaaaaaa';
	},
	'cig_sha256': function(file, signature) {
		// Decrypt from base64 to binary and write to a tmp file
		let decoded = b64dec(signature);
		if (!decoded) {
			return false;
		}
		let pub_key_file_name = "/etc/ucentral/sign_pubkey.pem";
		let sign_file_name = "/tmp/sign_file.txt";
		let sign_file = fs.open(sign_file_name, "w");
		sign_file.write(decoded);
		sign_file.close();

		// Verify the signature
		let sign_verify_cmd = "openssl dgst -sha256 -verify " + pub_key_file_name + " -signature " + sign_file_name + " " + file;
		let pipe = fs.popen(sign_verify_cmd);
		let result = pipe.read("all");
		let retcode = pipe.close();
		// Return code of 0 is valid signature
		if (retcode == 0) {
			return true;
		} else {
			return false;
		}
	},
};

return {

verify: function(file, signature) {
	let func = key_info[restrict?.key_info?.vendor + '_' + restrict?.key_info?.algo];

	if (!func)
		return false;

	return func(file, signature);
},

}

