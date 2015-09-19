// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//

//= require jquery
//= require jquery_ujs
//= require bootstrap-sass/assets/javascripts/bootstrap
//= require bootstrap-material-design/dist/js/material
//= require bootstrap-material-design/dist/js/ripples

//= require components/landing_page.js
//= require components/course_detail.js
//= require components/lecture.js
//= require components/learning.js
//= require components/rating.js
//= require components/filter.js
//= require components/sorting.js
//= require components/list_course.js
//= require components/payment_card.js
//= require components/payment.js
//= require ./components/nav
//= require components/home
//= require components/preview
//= require components/wishlist

$(document).ready(function () {
  $.material.init();
  $.material.ripples();
  $.material.input();
  $('.active-nav-1').sliderDropdown();
  $('.active-nav-2').sliderDropdown();
});

$(document).ajaxError(function (e, xhr, settings) {
  if (xhr.status == 401) {
    var course_id = gup('course_id', settings['url'])
    window.location.replace("/users/sign_in?tcode=" + course_id)
  }
});

function gup( name, url ) {
  if (!url) url = location.href
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( url );
  return results == null ? null : results[1];
}

(function (d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s);
  js.id = id;
  js.src = "//connect.facebook.net/vi_VN/sdk.js#xfbml=1&version=v2.4&appId=1592966984299237";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
