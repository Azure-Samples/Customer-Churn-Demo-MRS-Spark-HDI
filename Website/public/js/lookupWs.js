//maml-server.js

var http = require("http");
var https = require("https");
var querystring = require("querystring");
var fs = require('fs');

var getPred = function(id) {

	var dataString = JSON.stringify(data)
	var host = 'ussouthcentral.services.azureml.net'
	var path = '/workspaces/fda91d2e52b74ee2ae68b1aac4dba8b9/services/1b2f5e6f99574756a8fde751def19a0a/execute?api-version=2.0&details=true'
	var method = 'POST'
	var api_key = 'vKKR78dSdQeSc9qdMaDmu2Z5bcFqb4TfkZdNgSxzcIjGV9p5OP2uy4k1HfJes1T4Ws3St+EBgQTX/N8vqCs4zg=='
	var headers = {'Content-Type':'application/json', 'Authorization':'Bearer ' + api_key};

	var options = {
		host: host,
		port: 443,
		path: path,
		method: 'POST',
		headers: headers
	};

	data = buildInputData(id)
	var reqPost = https.request(options, function (res) {
		//console.log('===reqPost()===');
		//console.log('StatusCode: ', res.statusCode);
		//console.log('headers: ', res.headers);

		res.on('data', function(d) {
			process.stdout.write(d);
		});
	});

	// Would need more parsing out of prediction from the result
	reqPost.write(dataString);
	reqPost.end();
	reqPost.on('error', function(e){
		console.error(e);
	});
}

//Could build feature inputs from web form or RDMS. This is the new data that needs to be passed to the web service.

var buildInputData = function(id){
	var data = {
		"Inputs": {
			"input1″: {
				"ColumnNames": ["gl10″, "roc20″, "uo", "ppo", "ppos", "macd", "macds", "sstok", "sstod", "pmo", "pmos", "wmpr"],
				"Values": [ [ "0", "-1.3351″, "50.2268", "-0.2693″, "-0.2831″, "-5.5310″, "-5.8120″, "61.9220", "45.3998", "-0.0653″, "-0.0659″, "-30.3005″ ], ]
			},
		},
		"GlobalParameters": {}
	}
	return (data);
}

function send404Reponse(response) {
response.writeHead(404, {"Context-Type": "text/plain"});
response.write("Error 404: Page not Found!");
response.end();
}

function onRequest(request, response) {
	if(request.method == 'GET' && request.url == '/' ){
		response.writeHead(200, {"Context-Type": "text/plain"});
		fs.createReadStream("./index.html").pipe(response);
	}else {
		send404Reponse(response);
	}
}
 
http.createServer(onRequest).listen(8050);
console.log("Server is now running on port 8050″);
buildFeatureInput();