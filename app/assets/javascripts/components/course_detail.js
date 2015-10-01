(function ($) {
  $(document).ready(function() {
    if (window.location.href.match('/detail') != null) {
      var course_id = $(".course_id").val();
      var utm_source = getParameterByName('utm_source');
      // Tracking L2
      var params = {
        'category': 'L2',
        'behaviour': 'view',
        'target': course_id,
        'extras': {
          'chanel': utm_source == undefined ?  document.referrer : utm_source
        }
      };
      Spymaster.track(params);
    } 
  });

  function saleCoundownter(duration, ondisplay, ontimeout) {
    var timer = duration,
      days, hours, minutes, seconds;
    var interval = setInterval(function () {
      if (--timer < 0) {
        ontimeout ? ontimeout() : null
        clearInterval(interval);
        return;
      }

      days = parseInt(timer / 60 / 60 / 24, 10)
      hours = parseInt(timer / 60 / 60 % 24, 10)
      minutes = parseInt(timer / 60 % 60, 10);
      seconds = parseInt(timer % 60, 10);

      days = days < 10 ? "0" + days : days;
      hours = hours < 10 ? "0" + hours : hours;
      minutes = minutes < 10 ? "0" + minutes : minutes;
      seconds = seconds < 10 ? "0" + seconds : seconds;

      ondisplay(days, hours, minutes, seconds);

    }, 1000);
  };

  // Start countdown if there is a sale
  if (tag = $("#sale-expired-time")[0]) {
    stop_time = (new Date(Number(tag.value))).getTime();

    var tag_day = $("#countdown-day")[0];
    var tag_hour = $("#countdown-hour")[0];
    var tag_minute = $("#countdown-minute")[0];
    var tag_second = $("#countdown-second")[0];
    saleCoundownter(
      (stop_time - Date.now()) / 1000,
      function (days, hours, minutes, seconds) {
        tag_day.textContent = days;
        tag_hour.textContent = hours;
        tag_minute.textContent = minutes;
        tag_second.textContent = seconds;
      },
      function () {
        alert("Hết thời gian sale");
      });
  } else {
    console.debug("Not found sale countdown");
  };
  var getCurrentElement = function (top) {

    var lstDetect = $(".menu-fixed .nav-pills a");
    for (var i = lstDetect.length - 1; i >= 0; i--) {
      var element = $(lstDetect[i]).attr("href");
      if ($(element).offset().top - 100 <= top) {
        return element;
      }
    };
  };

  $.fn.setActive = function () {
    this.click(function () {
      $(".active").removeClass("active");
      $(this).addClass("active");
    });
  };

  $.fn.documentScroll = function () {
    // get hash url and set active
    var hash = window.location.hash;
    if (hash.trim() != "") {
      $(".active").removeClass("active");
      $(".menu-fixed a[href=" + hash + "]").parent().addClass("active");
    }

    if ($(document).scrollTop() >= $("#description").offset().top - 100) {
      $(".menu-fixed").css("display", "block");
    }

    this.scroll(function () {

      var scrollTop = $(document).scrollTop();
      if (scrollTop >= $("#description").offset().top - 100) {
        $(".menu-fixed").css("display", "block");
      } else {
        $(".menu-fixed").css("display", "none");
      }
      $(".active").removeClass("active");
      $(".menu-fixed a[href=" + getCurrentElement(scrollTop) + "]").parent().addClass("active");
    });

  };
  // check to active handle for scroll
  if ($(".detail").length != 0) {

    $(document).documentScroll();
    $(".menu-fixed li").setActive();

  };

  $(".show-form").click(function () {
    $(".tele-sales").css("display", "none");
    $(".tele-sales-extend").css("display", "block");
    $(".name-input").focus();
  });

  $(".hide-form").click(function () {
    $(".tele-sales-extend").css("display", "none");
    $(".tele-sales").css("display", "block");
  });

  $(".send-form-support").click(function () {

    var course_id = $(".course_id").val();
    var course_name = $(".course_name").val();
    var user_id = $(".user_id").val();
    var user_email = $(".user_email").val();
    var name = $(".name-input").val();
    var mobile = $(".mobile-input").val();

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

    var URL = 'http://flow.pedia.vn:8000/notify/course_page_support/create';
    var request = $.ajax({
      url: URL,
      type: "post",
      data: params,
    });

    // Callback handler that will be called on success
    request.done(function (response, textStatus, jqXHR) {
      // Log a message to the console
      $(".tele-sales-content").css("display", "none");
      $(".support-online-payment-form .success").css("display", "block");
    });

    // Callback handler that will be called on failure
    request.fail(function (jqXHR, textStatus, errorThrown) {
      // Log the error to the console
    });
  });

})(jQuery);

$(document).ready(function () {

  $(".wishlist-button").click(function () {
    var course_id = $(".course_id").val();

    var params = {
      'course_id': course_id,
    }

    var URL = 'http://' + window.location.host + '/home/my-course/update_wishlist';
    $.ajax({
      type: 'GET',
      url: URL,
      data: params,
      success: function (msg) {
        if ($(".wishlist-button").hasClass("wishlisted")) {
          $(".wishlist-button").removeClass("wishlisted");
        } else {
          $(".wishlist-button").addClass("wishlisted");
        };
      }
    });

  });

  $(".buy-button").click(function () {
    var course_id = $(".course_id").val();
    var utm_source = getParameterByName('utm_source');
    // Tracking L7a
    var params = {
      'category': 'L7a',
      'behaviour': 'click',
      'target': course_id,
      'extras': {
        'chanel': utm_source == undefined ?  document.referrer : utm_source 
      }
    };
    Spymaster.track(params);
  });

  $(".btn-submit-report").click(function () {
    var course_id = $(".course_id").val();
    var content = $(".txt-report-content").val();
    var type = "other"
    if (content == "") {
      return;
    }
    var params = {
      'type': type,
      'course_id': course_id,
      'content': content
    }

    var URL = 'http://' + window.location.host + '/support/send_report';
    $.ajax({
      type: 'POST',
      url: URL,
      data: params,
      success: function (msg) {
        $(".txt-report-content").val("");
      }
    });
  });

  $(".submit-cod-code").on("click", function () {

    var parent = $($(this).parent()).parent();
    $(".txtNoti").css("display", "none");
    var input_code = $(parent).find("input[type=text]");
    var cod_code = input_code.val();
    var payment_id = input_code.attr("payment_id");

    if (cod_code.trim() == "") {
      input_code.focus();
      return;
    }
    if (payment_id.trim() == "") {
      return;
    }
    var params = {
      'cod_code': cod_code,
    }
    var URL = '/home/payment/cod/' + payment_id + '/import_code';
    $.ajax({
      type: 'POST',
      url: URL,
      data: params,
      success: function (data, textStatus, xhr) {
        $(".txtNoti").text(xhr.responseJSON.message);
        $(".txtNoti").css("display", "block");
        setTimeout(function () { // wait for 5 secs(2)
          location.reload(); // then reload the page.(3)
        }, 3000);
      },
      complete: function (xhr, textStatus) {
        $(".txtNoti").text(xhr.responseJSON.message);
        $(".txtNoti").css("display", "block");
      }
    });

  });

  $(".load-more").click(function () {
    if ($(".description-first").hasClass("short_description")) {
      $(".description-first").removeClass("short_description");
      $(".description-first").addClass("long_description");
      $(this).text("Thu gọn");
    } else {
      $(".description-first").removeClass("long_description");
      $(".description-first").addClass("short_description");
      $(this).text("Xem chi tiết");
    };

  });

  function number_to_currency(price, unit, delimiter) {
    unit = unit || "đ";
    delimiter = delimiter || ",";

    return price.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + delimiter) + unit;
  };

  // get param url
  function getParameterByName(name, url) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
      results = regex.exec(url);
    return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
  }
});