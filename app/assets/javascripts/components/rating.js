(function ($) {

  var boss = null;
  // close popup
  var handleClose = function () {
    $(".rating-popup").remove();
    $(".rating-popup-background").remove();
    $("#rating-title").val("");
    $("#rating-content").val("");

  }
  $.fn.ratingPopup = function () {

    this.click(function () {

      handleClose();
    });
  };

  $.fn.sendRatingHandle = function () {
    this.click(function () {

      var ratingTitle = $("#rating-title").val();
      var ratingContent = $("#rating-content").val();
      var ratingNumber = $($(".rating-popup")[0]).find(".rated").length;
      var course_id = boss.attr("course_id");

      var params = {
        'title': ratingTitle,
        'description': ratingContent,
        'rate': ratingNumber
      }

      var URL = '//' + window.location.host + '/courses/' + course_id + '/rating';
      $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function (msg) {
          handleClose();
        }
      });
      // do something
    })
  }

  // open popup
  $.fn.ratingOpenPopup = function () {

    this.click(function () {

      var bg = "<div class='rating-popup-background'></div>"
      var htmlPopup =
        "<div class='col-xs-12 col-sm-8 col-md-6 col-lg-4 no-padding rating-popup'> <div class='row rating-popup-title'> <span>Đánh giá khoá học</span> <i class='fa fa-times rating-popup-close'></i> </div> <div class='row rating-popup-main'> <div class='row no-margin'> <span>Đánh giá :</span> <ul class='no-padding rating'>";

      // get default value for popup rating
      var num_rate = $(this).attr("data-rate");
      var title = $(this).attr("data-title");
      var description = $(this).attr("data-description");

      // set rated for star in popup
      for (var i = 1; i <= 5; i++) {

        if (i <= num_rate) {
          htmlPopup += "<li> <i class='fa fa-star star rated' val='" + i + "'></i> </li>";
        } else {
          htmlPopup += "<li> <i class='fa fa-star star' val='" + i + "'></i> </li>";
        }
      }
      htmlPopup +=
        "</ul> </div> <div class='row no-margin'> <input name='star' type='hidden' value='5'><input class='form-control' id='rating-title' placeholder='Tiêu đề'> <textarea class='form-control' id='rating-content' placeholder='Nội dung'></textarea> <button class='btn btn-primary' id='rating-submit'>Đánh giá</button> </div> </div> </div> "

      // append popup to dom
      $("body").append(bg);
      $("body").append(htmlPopup);
      $(".rating-popup").fadeIn();

      // set value for title and description in popup
      $("#rating-title").val(title);
      $("#rating-content").val(description);

      // init handle for close popup and star
      $(".rating-popup .rating-popup-close").ratingPopup();
      boss = $(this);
      $(".rating-popup .star").moveOnStar();
      //init handle for submit rating
      $("#rating-submit").sendRatingHandle();

      return false;

    });
  }
  $(".rating-active").ratingOpenPopup();

  // handle and detect move on star
  $.fn.moveOnStar = function () {
    this.on("click", function () {

      if (boss == null) {
        return;
      }

      var valueStar = parseInt($(this).attr("val"));
      var ratings = $(boss);
      ratings.push($(".rating-popup"));

      $("input[name=star]").val(valueStar);

      ratings.each(function () {

        var itemStars = $(this).find(".star");

        if (itemStars.length != 0) {
          itemStars.each(function () {
            if (parseInt($(this).attr("val")) <= valueStar) {
              $(this).addClass("rated");
            } else {
              $(this).removeClass("rated");
            }
          });
        };
      });
    });
  };
  // $(".star").moveOnStar(".rating-active");

}(jQuery))