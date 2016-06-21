// JavaScript Document
var scoreClaim = function(id){ 
    //first get the rest of the data for this id
    // call /predict to get res.prob, the probability of returning the shipment
    $.ajax({
    url: '/predict',
    type: 'GET',
    data: { id },
    contentType:"application/json; charset=utf-8",
    error: function(xhr, error){
        console.log(xhr); console.log(error);
    }, 
    success: function(res) { 
       console.log("AccountID: " + id )
       console.log("churn return: " + res.pred )
            // now use the probability to display one of two message 
            if (res.pred > 0.5) {  //problem with this order; 
				$("#welcomemsg").html('There is a problem with this order.  Please call 800-555-2222 for more information');

			} else { // no problem with the order
				$("#welcomemsg").html('There is a problem with this order.  Please call 800-555-2222 for more information');
			}
        }   
        
       });	
}	
