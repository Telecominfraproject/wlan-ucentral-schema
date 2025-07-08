let ret = system("est_client reenroll");
result_json({
        "error": ret,
        "text": ret ? "Failed" : "Success",
        "resultCode": ret,
});

if (!ret)
        system("(sleep 10; /etc/init.d/ucentral restart)&");
