(function ($){

  // close popup
  var handleClose = function () {
    $(".rating-popup").remove();
    $(".rating-popup-background").remove();
  }
  $.fn.ratingPopup = function () {

    this.click( function () { 

      handleClose();
    });
  };

  // open popup
  $.fn.ratingOpenPopup = function () {
    var bg = "<div class='rating-popup-background'></div>"
    var htmlPopup = "<div class='col-xs-12 col-sm-8 col-md-6 col-lg-4 no-padding rating-popup'> <div class='row rating-popup-title'> <span>Đánh giá khoá học</span> <i class='fa fa-times rating-popup-close'></i> </div> <div class='row rating-popup-main'> <div class='row no-margin'> <span>Đánh giá :</span> <ul class='no-padding rating'> <li> <i class='fa fa-star star rated' val='1'></i> </li> <li> <i class='fa fa-star star rated' val='2'></i> </li> <li> <i class='fa fa-star star rated' val='3'></i> </li> <li> <i class='fa fa-star star rated' val='4'></i> </li> <li> <i class='fa fa-star star' val='5'></i> </li> </ul> </div> <form> <input name='star' type='hidden' value='5'> <input class='form-control' placeholder='Tiêu đề'> <textarea class='form-control' placeholder='Nội dung'></textarea> <button class='btn btn-primary'>Đánh giá</button> </form> </div> </div> ";
    this.click( function () {
      
      $("body").append(bg);
      $("body").append(htmlPopup);
      $(".rating-popup").fadeIn();
      // init handle for close popup and star
      $(".rating-popup .rating-popup-close").ratingPopup();
      $(".star").moveOnStar();
    });
  }
  $(".rating-active").ratingOpenPopup();

  // handle and detect move on star
  $.fn.moveOnStar = function () {
    this.on("click", function () {

      var valueStar = parseInt($(this).attr("val"));
      var ratings = $(".rating-active");
      $("input[name=star]").val(valueStar);
      ratings.each( function (){
        var itemStars = $(this).find(".star");
        if(itemStars.length != 0) {
          itemStars.each(function () {
            if(parseInt($(this).attr("val")) <= valueStar) {
              $(this).addClass("rated");
            }
            else {
              $(this).removeClass("rated");
            }
          });
        };
      });
    });
  };
  $(".star").moveOnStar();

}(jQuery))