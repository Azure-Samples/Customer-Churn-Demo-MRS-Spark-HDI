// JavaScript Document

$(document).ready ( function () {
			//$("#resultArea").hide();
            //$("#status").hide();

        $("#loginBtn").click(function(){ 
            acctID =  $("#login_username").val(); 
                //$("#resultArea").removeClass('hide');
                //$("#resultArea").addClass('show');			
				//$("#welcomemsg").html('There is a problem with this order.  Please call 800-555-2222 for more information');
                        $("#resultArea").removeClass('alert-danger');
                        $("#resultArea").addClass('alert-success');			
            // also make sure the account id is present.
            if (acctID !== '') {
                // show the status message and call scoreClaim
                //$("#status").removeClass('hide');
                //$("#status").addClass('show');
                //$("#status").fadeIn();
                scoreClaim(acctID);  
				$('#login-modal').modal('hide');
                } else {
                // no account ID present
                //$("#status").removeClass('show');   
                //$("#status").addClass('hide');
                $("#resultArea").html('Please enter your Account ID and password try again.');
                $("#resultArea").removeClass('alert-success');
                $("#resultArea").addClass('alert-danger');
                $("#resultArea").fadeIn();
                }
      }); 
   
});
            