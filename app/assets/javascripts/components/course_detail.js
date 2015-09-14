(function ($) {

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

    if ($(document).scrollTop() >= $($(".description")[4]).offset().top - 100) {
      $(".menu-fixed").css("display", "block");
    }

    this.scroll(function () {

      var scrollTop = $(document).scrollTop();
      if (scrollTop >= $($(".description")[4]).offset().top - 100) {
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

})(jQuery);

$(document).ready(function () {

  $(".submit-cod-code").on("click", function () {
    console.log("clicked");

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
    if ($(".description-content").hasClass("short_description")) {
      $(".description-content").removeClass("short_description");
      $(".description-content").addClass("long_description");
      $(this).text("Thu gọn");
    } else {
      $(".description-content").removeClass("long_description");
      $(".description-content").addClass("short_description");
      $(this).text("Xem chi tiết");
    };
    
  });

  // $("#submit-coupon-code").on("click", function () {
  //   var input_code = $("#coupon-code-container input[type=text]")
  //   var coupon_code = input_code.val();
  //   var course_id = input_code.attr("course_id");
  //   var price = input_code.attr("price");
  //   var discount = input_code.attr("discount");

  //   if (coupon_code.trim() == "") {
  //     input_code.focus();
  //     return;
  //   }
  //   if (course_id.trim() == "") {
  //     return;
  //   }

  //   var URL = "http://code.pedia.vn/coupon";
  //   var params = {coupon: coupon_code, q: Math.random()}
  //   $.ajax({
  //     type: 'GET',
  //     url: URL,
  //     data: params,
  //     success: function (data, textStatus, xhr) {
  //       // if (xhr.responseJSON.course_id == course_id) {
  //       //   discount = parseFloat(discount) + parseFloat(xhr.responseJSON.return_value);
  //       //   price = (parseInt(price) * (100 - discount) / 100 / 1000) * 1000;
  //       //   $(".course-price").text(number_to_currency(price, "đ", ","));
  //       //   $(".discount").text("(Giảm giá: " + discount + "%)");

  //       //   var coupon_code_param = getParameterByName("coupon_code", $("#btn-buy").attr("href"));
  //       //   if (coupon_code_param == "") {
  //       //     $("#btn-buy").attr("href", $("#btn-buy").attr("href") + "&coupon_code=" + coupon_code);
  //       //   } else if (coupon_code_param.split(",").indexOf(coupon_code) < 0) {
  //       //     $("#btn-buy").attr("href", $("#btn-buy").attr("href") + "," + coupon_code);
  //       //   };
  //       // } else {
  //       //   $("#coupon-code-container input[type=text]").val("Mã coupon không tồn tại");
  //       // };
  //     },
  //     complete: function (xhr, textStatus) {
  //       if (xhr.responseJSON.course_id == course_id) {
  //         discount = parseFloat(discount) + parseFloat(xhr.responseJSON.return_value);
  //         price = parseInt((parseInt(price) * (100 - discount) / 100 / 1000)) * 1000;
  //         $(".course-price").text(number_to_currency(price, "đ", ","));
  //         $(".discount").text("(Giảm giá: " + discount + "%)");

  //         var coupon_code_param = getParameterByName("coupon_code", $("#btn-buy").attr("href"));
  //         if (coupon_code_param == "") {
  //           $("#btn-buy").attr("href", $("#btn-buy").attr("href") + "&coupon_code=" + coupon_code);
  //         } else if (coupon_code_param.split(",").indexOf(coupon_code) < 0) {
  //           $("#btn-buy").attr("href", $("#btn-buy").attr("href") + "," + coupon_code);
  //         };
  //         d = new Date(xhr.responseJSON.expired_date);
          
  //         $("#expired_date").text("Ngày hết hạn: " + d.getDate() + "/" +(d.getMonth() + 1) + "/" + d.getFullYear());
  //         $("#coupon-code-container").remove();
  //         $("#line-through-price").css("display", "block");
  //       } else {
  //         $("#coupon-code-container input[type=text]").val("Mã coupon không tồn tại");
  //       };
  //     }
  //   });
  // });

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
