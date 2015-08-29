$(document).ready(function (){

  $("#submit-cod-code").on("click", function(){
    $("#txtNoti").css("display","none");
    var input_code = $("#cod-code-container input[type=text]")
    var cod_code = input_code.val();
    var payment_id = input_code.attr("payment_id");

    if(cod_code.trim() == ""){
      input_code.focus();
      return;
    }
    if(payment_id.trim() == ""){
      return;
    }
    var params = {
      'cod_code' : cod_code,
    }
    var URL = '/home/payment/cod/' + payment_id + '/import_code';
    $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function(data, textStatus, xhr){
            $("#txtNoti").text(xhr.responseJSON.message);
          $("#txtNoti").css("display","block");
        },
        complete: function(xhr, textStatus) {
          $("#txtNoti").text(xhr.responseJSON.message);
          $("#txtNoti").css("display","block");
        } 
      });

  });

})