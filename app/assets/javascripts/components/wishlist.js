(function ($) {
  
  $.fn.wishlist = function () {
    this.click( function () {
      var course_id = $(this).attr('val');
      var params = {
        'course_id': course_id,
      }

      var heart = $(this).children().children().get(1);
      if (heart.classList.contains("wishlist")){
        heart.classList.remove("wishlist");
      }else{
        heart.classList.add("wishlist"); 
      }

      var URL = 'http://' + window.location.host + '/home/my-course/update_wishlist';
      $.ajax({
          type: 'GET',
          url: URL,
          data: params,
          success: function(msg){
          }
        });
      })
  };

  $('.wishlist-heart').wishlist();

})(jQuery);