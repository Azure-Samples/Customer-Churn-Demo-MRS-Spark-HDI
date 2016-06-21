// JavaScript Document
var scoreClaim = function(id){ 
  var webserviceurl='https://ussouthcentral.services.azureml.net/workspaces/615a80e32b53433399b91a3c09464bc3/services/612c1ca9ead94442a3c8b525033cb3cd/execute?api-version=2.0&details=true';
  var apiKey='MbUq2PfVw65FQHi4rFt57lWjdmzxY8C5nXxXFMGVdSrC4uoAJOyWG6WwwI1xUvfsHx2V/ojnPiFGyLcyRMcYjA==';
  
  var dataString =  '{"Inputs": {"input1": {"ColumnNames": ["x"],"Values": [["'+ id +'"]]}},"GlobalParameters": {}}';
  var inputData = JSON.parse(dataString);
  console.log(inputData)
  
  $.ajax({
        url: webserviceurl,
        type: "POST",           
        data: inputData,            
        dataType:'json',                        
        headers: {
        "Content-Type":"application/json;charset=utf-8",            
        "Authorization":"Bearer " + apiKey                       
        },
        success: function (data) {
          console.log('Success');
        },
        error: function (data) {
           console.log('Failure ' +  data.statusText + " " + data.status);
        },
  });
}	
