// JavaScript Document
var scoreClaim = function(id){ 
    //first get the rest of the data for this id
    record = lookupData(id, amt)
    // call /predict to get res.prob, the probability of returning the shipment
	
	
$.ajax({
  type: 'GET',
  headers: {'X-Parse-Application-Id':'PARSE-APP-ID','X-Parse-REST-API-Key':'PARSE-REST-KEY'},
  url: "https://api.parse.com/1/users",
  data: 'where={"username":"someUser"}',
  contentType: "application/json"
});
	
	var data = {
		"Inputs": {
			"input1″: {
				"ColumnNames": ["gl10″, "roc20″, "uo", "ppo", "ppos", "macd", "macds", "sstok", "sstod", "pmo", "pmos", "wmpr"],
				"Values": [ [ "0", "-1.3351″, "50.2268", "-0.2693″, "-0.2831″, "-5.5310″, "-5.8120″, "61.9220", "45.3998", "-0.0653″, "-0.0659″, "-30.3005″ ], ]
			},
		}

api_key = 'abc123' # Replace this with the API key for the web service
headers = {'Content-Type':'application/json', 'Authorization':('Bearer '+ api_key)}
		
$.ajax({
  type: 'POST',
  headers: {'X-Parse-Application-Id':'PARSE-APP-ID','X-Parse-REST-API-Key':'PARSE-REST-KEY'},
  url: "https://ussouthcentral.services.azureml.net/workspaces/fda91d2e52b74ee2ae68b1aac4dba8b9/services/1b2f5e6f99574756a8fde751def19a0a/execute?api-version=2.0&details=true",
  data: 'where={"x":"someUser"}',
  contentType: "application/json"
});

//http://stackoverflow.com/questions/27987910/azure-machine-learning-cors
//http://stackoverflow.com/questions/37418265/azure-machine-learning-using-javascript-ajax-call

$(document).ready(function () {
    var ajaxData = "-- the request body ";
    var serviceUrl = "https://ussouthcentral.services.azureml.net/workspaces/00e36959fc3e4673a32eae9f9b184346/--whatever";

    $.ajax({
        type: "POST",
        url: serviceUrl,
        data: ajaxData,
		dataType:'jsonp'
        headers: {
            "Authorization": "Bearer " + apiKey,  // --API KEY HERE--",
            "Content-Type": "application/json;charset=utf-8"
        }
    }).done(function (data) {
        console.log(data);
    });
});

var obj = jQuery.parseJSON('{"name":"John"}');
alert( obj.name === "John" );

data =  {
	"Inputs": {
		"input1": {
			"ColumnNames": ["x"],
			"Values": [
				["0"]
			]
		}
	},
	"GlobalParameters": {}
}

	
  $.ajax({
        url: webserviceurl,
        type: "POST",           
        data: sampleData,            
        dataType:'jsonp',                        
        headers: {
        "Content-Type":"application/json",            
        "Authorization":"Bearer " + apiKey                       
        },
        success: function (data) {
          console.log('Success');
        },
        error: function (data) {
           console.log('Failure ' +  data.statusText + " " + data.status);
        },
  });
  
    $.ajax({
    url: '/predict',
    type: 'GET',
    data: { record: record },
    contentType:"application/json; charset=utf-8",
    error: function(xhr, error){
        console.log(xhr); console.log(error);
    }, 
    success: function(res) { 
       console.log("AccountID: " + id )
       console.log("Predicted probability: " + res.pred )
            // now use the probability to display one of two message 
            if (res.pred > 0.5) {  //problem with this order; 
                $("#resultArea").html('There is a problem with this order.  Please call 800-555-2222 for more information');
                        $("#resultArea").removeClass('alert-success');
                        $("#resultArea").addClass('alert-danger');		

                    } else { // no problem with the order
                $("#resultArea").html('Thank you for submitting your order. You will receive an email with tracking information shortly.');
                        $("#resultArea").removeClass('alert-danger');
                        $("#resultArea").addClass('alert-success');
                    }
            $("#resultArea").fadeIn();
        }   
        
       });	
}	

var lookupData = function(custID){
    
// the rest of the record would be looked up in a SQL database, for this demo we are simply supplying the info directly
var record =  '6C0E80FA-6988-4823-B0F5-BA49EBCBD99E,'+ custID + ',100,100,USD,'
var record = record + '"",20130401,2932,21,A,P,"","","",'
var record = record + '201.8,minas gerais,30000-000,br,False,"",pt-BR,CREDITCARD,VISA,"","","",30170-000,MG,BR,'
var record = record + '"","","","","","",M,"",1,0,"","","",30170-000,"",MG,BR,"",1,False,0.000694444444444444,0,0,0,"",0'
return(record);
}
