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
//= require materialize-sprockets
//= require_tree ./components

$('.btn-sidenav-activator').sideNav();
// $('.sorting .sorting-options').material_select();
$('.modal-trigger').leanModal();
$('.dropdown-button').dropdown({
  inDuration: 300,
  outDuration: 225,
  constrain_width: true, // Does not change width of dropdown to that of the activator
  hover: false, // Activate on hover
  gutter: 0, // Spacing from edge
  belowOrigin: true // Displays dropdown below the button
});

(function (d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s);
  js.id = id;
  js.src = "//connect.facebook.net/vi_VN/sdk.js#xfbml=1&version=v2.4&appId=1592966984299237";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));