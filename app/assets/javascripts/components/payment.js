'use strict';

$(document).ready(function () {
  var element = $('.row.payment-content.active');
  if (element.length > 0) {
    $('html, body').animate({
      scrollTop: element.offset().top
    }, 1000);
  }

  // set selected for provider
  $("#list-provider li").on("click", function(){
    
    var provider = $(this).attr("val");
    $("#card-id").val(provider);
    $(".active-provider").removeClass("active-provider");
    $(this).addClass("active-provider");
  });

  // add effect when choose menthod purchase online_payment
  $.fn.selectmenthod = function () {
    this.click(function () {
      $(".selected").removeClass("selected");
      $(this).addClass("selected");
    });
  };
  $(".select-card").selectmenthod();

  $(".send-form-support").click(function () {

    var course_id = $(".course_id").val();
    var course_name = $(".course_name").val();
    var user_id = $(".user_id").val();
    var user_email = $(".user_email").val();
    var name = $(".name-input").val();
    var mobile = $(".mobile-input").val();


    var params = {
      'course_id': course_id,
      'course_name' : course_name,
      'user_id': user_id,
      'email' : user_email,
      'name': name,
      'mobile': mobile,
      'type' : 'course_page_support',
      'msg' : name + ' cần hỗ trợ tại khóa học ' + course_name,
      // 'payment_id'
    }

    var URL = 'http://flow.pedia.vn:8000/notify/course_page_support/create';
    var request = $.ajax({
        url: URL,
        type: "post",
        data: params,
    });

    // Callback handler that will be called on success
    request.done(function (response, textStatus, jqXHR){
        // Log a message to the console
        $(".tele-sales-content").css("display", "none");
        $(".tele-sales-extend .success").css("display", "block");
    });

    // Callback handler that will be called on failure
    request.fail(function (jqXHR, textStatus, errorThrown){
        // Log the error to the console
    });
  });
  
}); 