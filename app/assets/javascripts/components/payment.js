'use strict';

$(document).ready(function () {
    alert("okd");
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

});