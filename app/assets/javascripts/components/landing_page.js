$(document).ready(function() {
  $('.carousel').carousel({interval: 5000});
  $(".link-exist-account").click(function(event){
    event.preventDefault();
    $(".wrapper-register").fadeOut();
    $(".wrapper-login").fadeIn();
  });
  $(".link-dont-account").click(function(event) {
    event.preventDefault();
    $(".wrapper-login").fadeOut();
    $(".wrapper-register").fadeIn();
  });
});
