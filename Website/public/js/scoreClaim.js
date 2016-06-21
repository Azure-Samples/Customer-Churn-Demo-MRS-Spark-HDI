// JavaScript Document
var scoreClaim = function(id){ 
    //first get the rest of the data for this id
    // call /predict to get res.prob, the probability of returning the shipment
    $.ajax({
    url: '/predict',
	//url: '/',
    type: 'GET',
    data: { id: id },
    contentType:"application/json; charset=utf-8",
    error: function(xhr, error){
        console.log(xhr); console.log(error);
    }, 
    success: function(res) { 
       console.log("AccountID: " + id )
       console.log("churn return: " + res.pred )
            // now use the probability to display one of two message 
				//$("#welcomemsg").html(res.pred);
				$("#resultArea").html(res.pred);
        }   
       });	
}	
