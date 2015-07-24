'use strict';

$(document).ready(function () {
  // Popup login tracking
  $('#modal-login .btn-facebook').click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    ga('send', 'event', 'login-modal', 'login', 'Facebook login', {
      hitCallback: function () {
        window.location = '/users/auth/facebook';
      }
    });
  });

  $('#modal-login .btn-google').click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    ga('send', 'event', 'login-modal', 'login', 'Google login', {
      hitCallback: function () {
        window.location = '/users/auth/google_oauth2';
      }
    });
  });

  $('#modal-login input[type="submit"]').click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    ga('send', 'event', 'login-modal', 'login', 'Email login', {
      hitCallback: function () {
        $('#modal-login form').submit();
      }
    });
  });

  // Popup register tracking
  $('#modal-register .btn-facebook').click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    ga('send', 'event', 'register-modal', 'register', 'Facebook register', {
      hitCallback: function () {
        window.location = '/users/auth/facebook';
      }
    });
  });

  $('#modal-register .btn-google').click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    ga('send', 'event', 'register-modal', 'register', 'Google register', {
      hitCallback: function () {
        window.location = '/users/auth/google_oauth2';
      }
    });
  });

  $('#modal-register input[type="submit"]').click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    ga('send', 'event', 'register-modal', 'register', 'Email register', {
      hitCallback: function () {
        $('#modal-register form').submit();
      }
    });
  });

  $('#btn-buy').click(function (e) {
    e.preventDefault();
    e.stopPropagation();
    var link = $('#btn-buy').attr('href');
    ga('send', 'event', 'course', 'buy', 'Buy a course', {
      hitCallback: function () {
        window.location = link;
      }
    });
  });
});