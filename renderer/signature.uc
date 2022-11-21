let key_info = {
	'dummy_static': function(file, signature) {
		return signature == 'aaaaaaaaaa';
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

