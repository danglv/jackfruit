'use strict';

$(document).ready(function () {
  var element = $('.row.payment-content.active');
  if (element.length > 0) {
    $('html, body').animate({
      scrollTop: element.offset().top
    }, 1000);
  }

  // set selected for provider
  $("#list-provider li").on("click", function () {

    var provider = $(this).attr("val");
    $("#card-id").val(provider);
    $(".active-provider").removeClass("active-provider");
    $(this).addClass("active-provider");
  });

  // add effect when choose method purchase online_payment
  $.fn.selectmethod = function () {
    this.click(function () {
      $(".selected").removeClass("selected");
      $(this).addClass("selected");
    });
  };
  $(".select-card").selectmethod();

  $(".send-form-support").click(function () {

    var course_id = $(".course_id").val();
    var course_name = $(".course_name").val();
    var user_id = $(".user_id").val();
    var user_email = $(".user_email").val();
    var name = $(".name-input").val();
    var mobile = $(".mobile-input").val();

    var error_msg = null;
    if (name.length == 0)
      error_msg = "Hãy nhập tên của bạn để chúng tôi có thể liên hệ";
    else if (mobile.length == 0)
      error_msg = "Hãy nhập số điện thoại để chúng tôi có thể liên hệ với bạn";
    else if (mobile.length < 9)
      error_msg = "Số điện thoại không đúng, vui lòng kiểm tra lại";
    else{
      var phone_pattern = /^([0-9\(\)\/\+ \-]*)$/;
      if (!mobile.match(phone_pattern))
        error_msg = "Số điện thoại không hợp lệ, vui lòng kiểm tra lại";
    }
    if (error_msg){
      $("#payment-support-form > #validate-message").text(error_msg);
      $("#payment-support-form > #validate-message").css("display", "block");
      return;
    }else{
      $("#payment-support-form > #validate-message").css("display", "none");
    }

    var params = {
      'course_id': course_id,
      'course_name': course_name,
      'user_id': user_id,
      'email': user_email,
      'name': name,
      'mobile': mobile,
      'type': 'course_page_support',
      'msg': name + ' cần hỗ trợ tại khóa học ' + course_name,
      // 'payment_id'
    }

    var URL = 'http://' +  window.location.host + '/courses/api/send_form-support_detail';
    var request = $.ajax({
      url: URL,
      type: "post",
      data: params,
    });

    // Callback handler that will be called on success
    request.done(function (response, textStatus, jqXHR) {
      // Log a message to the console
      // $(".support-online-payment-form").css("display", "none");
      // $(".support-online-payment-form-success").css("display", "block");
      // Show popup
      $('#support_success_modal').modal('show');
    });

    // Callback handler that will be called on failure
    request.fail(function (jqXHR, textStatus, errorThrown) {
      // Log the error to the console
    });
  });

  $(".btn-cod").click(function () {
    var course_id = $(".course_id").val();
    // Tracking L7b
    Spymaster.track({category: 'L7b', behavior: 'click', target: course_id, extras: {payment_method: 'cod'}});
  });

  $(".btn-transfer").click(function () {
    var course_id = $(".course_id").val();
    // Tracking L7b
    Spymaster.track({category: 'L7b', behavior: 'click', target: course_id, extras: {payment_method: 'transfer'}});
  });

  $(".btn-card").click(function () {
    var course_id = $(".course_id").val();
    // Tracking L7b
    Spymaster.track({category: 'L7b', behavior: 'click', target: course_id, extras: {payment_method: 'card'}});
  });

  $(".btn-cih").click(function () {
    var course_id = $(".course_id").val();
    // Tracking L7b
    Spymaster.track({category: 'L7b', behavior: 'click', target: course_id, extras: {payment_method: 'cih'}});
  });
});