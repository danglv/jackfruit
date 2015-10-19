'use strict';

$(document).ready(function() {
  $('.reset-password-button').click(function(event) {
    var email = $("#email-reset").val();
    var URL = "/users/forgot_password?email=" + email;

    var params = {
      'email': email
    }

    var request = $.ajax({
      url: URL,
      type: "post",
      data: params,
      success: function (msg) {
        $(".forgot-password-content").css("display", "none");
        $(".forgot-password-content-success").css("display", "block");
      }
    });
  });
  $('.login').click(function() {
    $('#fogot-password-dialog').modal('hide');
  })
});