var express = require('express');
var http = require('http');
var https = require('https');
var querystring = require('querystring');
var fs = require('fs');

var app = express();
var exphbs  = require('express-handlebars');
app.engine('handlebars', exphbs({defaultLayout: 'main'}));
app.set('view engine', 'handlebars');

app.use(express.static('public'));

// Home Page
app.get('/', function (req, res) {
            res.render('home') 
});

// Test Page
app.get('/test', function (req, res) {
            res.render('test') 
});

// predict function, called from scoreClaim.js
app.get('/predict', function (req, res) {

	//  *******************************************
	// replace with the webservice info we publish by the demo
    var path = '/workspaces/615a80e32b53433399b91a3c09464bc3/services/612c1ca9ead94442a3c8b525033cb3cd/execute?api-version=2.0&details=true'
    var api_key = 'MbUq2PfVw65FQHi4rFt57lWjdmzxY8C5nXxXFMGVdSrC4uoAJOyWG6WwwI1xUvfsHx2V/ojnPiFGyLcyRMcYjA=='
	//  *******************************************
	
	var host = 'ussouthcentral.services.azureml.net'
	var method = 'POST'
	var headers = {'Content-Type':'application/json', 'Authorization':'Bearer ' + api_key};
	
	console.log('===getPred()===');
    var str = '';	

	var id = req.query.id;
    console.log (id)
	var data = {
		"Inputs": {
			"input1": {
				"ColumnNames": ["id"],
				"Values":  [[  id ]]
			}
		},
		"GlobalParameters": {}
	}
	
	var dataString = JSON.stringify(data)
	var options = {
		host: host,
		port: 443,
		path: path,
		method: 'POST',
		headers: headers
	};

	console.log('data: ' + dataString);
	console.log('method: ' + method);
	console.log('api_key: ' + api_key);
	console.log('headers: ' + headers);
	console.log('options: ' + options);

	var reqPost = https.request(options, function (response) {
		console.log('===reqPost()===');
		console.log('StatusCode: ', response.statusCode);
		console.log('headers: ', response.headers);

		response.on('data', function(chunk) {
			str += chunk;
		});

        response.on('end', function () {
              console.log(str);
		  var result = JSON.parse(str);
		  console.log(result.Results.output1.value.Values)
		  var value = result.Results.output1.value.Values
		  res.json({ pred: value });
        });		
		
	});
//result sample
/*
{"Results":{"output1":{"type":"table","value":{"ColumnNames":["pred"],"ColumnTypes":["String"],"Values":[["Welcome back t
o Joseph Mart!"]]}},"output2":{"type":"table","value":{"ColumnNames":["R Output JSON"],"ColumnTypes":["String"],"Values"
:[["{\"Standard Output\":\"RWorker pushed \\\"port1\\\" to R workspace.\\r\\n\",\"Standard Error\":\"R reported no error
s.\",\"visualizationType\":\"rOutput\",\"Graphics Device\":[\"iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgCAMAAABKCk6nAAAABlBMVEVkBg
D///+5/CcxAAAAAnRSTlMA/1uRIrUAAARTSURBVHic7dEBCQAwDMCwzb/pqTiHkigodJa0+R3AWwbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJ
zBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRxncJzBcQbHGRx3L2yELnclpkkAAAAASUVORK5CYII=\"]}"]]}}}}
*/

	// Would need more parsing out of prediction from the result
	reqPost.write(dataString);
	reqPost.end();
	reqPost.on('error', function(e){
		console.error(e);
	});
    //res.json({ pred: 0.8 });
});


app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});