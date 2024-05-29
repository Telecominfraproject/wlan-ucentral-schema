let msg = {
	raw: !!args.raw 
};
if (args.mac_address)
	msg.macaddr = args.mac_address;

system(`logger ${msg}\n`);

let fingerprint = ctx.call("fingerprint", "fingerprint", msg) || {};

result_json({
	"error": 0,
	"text": "Success",
	"resultCode": 0,
	"resultData": fingerprint,
});
