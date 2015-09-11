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

  // 
  $.fn.selectmenthod = function () {
    this.click(function () {
      $(".selected").removeClass("selected");
      $(this).addClass("selected");
      $(".credit-card-button").val($(this).attr("val"));
    });
  };
  $(".select-visa").selectmenthod();
});