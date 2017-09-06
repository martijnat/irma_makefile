var qrcode = require('qrcode-terminal');
var request = require('request');
var jwt = require("jsonwebtoken");
var fs = require('fs');

var iprequest = {
    data: "foobar",
    timeout: 60,
    request: {
        "credentials": [
            {
                "credential": "irma-demo.MijnOverheid.ageLower",
                "validity": 1482969600,
                "attributes": {
                    "over12": "yes",
                    "over16": "yes",
                    "over18": "yes",
                    "over21": "no"
                }
            },
            {
                "credential": "irma-demo.MijnOverheid.address",
                "validity": 1482969600,
                "attributes": {
                    "country": "The Netherlands",
                    "city": "Nijmegen",
                    "street": "Toernooiveld 212",
                    "zipcode": "6525 EC"
                }
            }
        ],
        "disclose": [
            {
                "label": "Age (higher)",
                "attributes": {
                    "irma-demo.MijnOverheid.ageHigher": "present"
                }
            }
        ]
    }
};

var jwtOptions = {
    algorithm: "none",
    issuer: "testip",
    subject: "issue_request"
};

var confpath = process.argv[3] != null ? process.argv[3] : 'src/main/resources';

// var keyfile = confpath + "/issuers/testip-sk.pem";
var token = jwt.sign({iprequest: iprequest}, null, jwtOptions);
console.log(token);
var server = process.argv[2] + "/irma_api_server/api/v2/issue/";
var result = null;

function poll(token) {
    var pollOptions = {
        uri: server + token + "/status",
        method: 'GET'
    };

    request(pollOptions, function (error, response, body) {
        if (body == '"INITIALIZED"' || body == '"CONNECTED"')
            process.stdout.write(".");
        else {
            console.log();
            console.log(body);
            result = body;
        }
    });
}

var options = {
    uri: server,
    method: 'POST',
    body: token
};

request(options, function (error, response, body) {
    if (!error && response.statusCode == 200) {
        var qrcontent = JSON.parse(body);
        var session = qrcontent.u;
        qrcontent.u = server + qrcontent.u;

        console.log(qrcontent);
        console.error(qrcontent);
        // qrcode.generate(JSON.stringify(qrcontent));

        var check = function() {
            if (result == null) {
                poll(session);
                setTimeout(check, 1000);
            }
        };

        check();
    } else {
        console.log("Error in initial request: ", error);
        console.log(body);
    }
});
