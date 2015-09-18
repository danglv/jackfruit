(function ($) {
  // $(this).click(function () {
  //   var course_id = $(this).attr('val');

  //   var params = {
  //     'course_id': course_id,
  //   }

  //   var URL = 'http://' + window.location.host + '/home/my-course/update_wishlist';
  //   $.ajax({
  //       type: 'POST',
  //       url: URL,
  //       data: params,
  //       success: function(msg){
  //       }
  //     });
  // })
  $.fn.wishlist = function (e) {
    this.click( function () {
      var course_id = $(this).attr('val');
      var params = {
        'course_id': course_id,
      }

      console.log($(this));

      var URL = 'http://' + window.location.host + '/home/my-course/update_wishlist';
      $.ajax({
          type: 'POST',
          url: URL,
          data: params,
          success: function(msg){
          }
        });
      e.preventDefault();
    })

  };

  $('.wishlist-heart').wishlist();

})(jQuery);