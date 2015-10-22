(function ($) {

  $.fn.wishlist = function () {
    this.click(function () {
      var course_id = $(this).attr('val');
      var params = {
        'course_id': course_id,
      }

      var heart = $(this).children().children().get(1);
      if (heart.classList.contains("wishlist")) {
        heart.classList.remove("wishlist");
      } else {
        heart.classList.add("wishlist");
      }

      var URL = 'https://' + window.location.host + '/home/my-course/update_wishlist';
      $.ajax({
        type: 'GET',
        url: URL,
        data: params,
        success: function (msg) {}
      });
    })
  };

  if (window.location.hash) {
    var hash = window.location.hash.substring(1);
    if (hash == "wishlist") {
      console.log($("#learning-tab"))
      $("#learning-tab").removeClass("active")
      $("#wishlist-tab").addClass("active")
      $("#myCourse-studying").removeClass("active")
      $("#myCourse-studying").removeClass("in")
      $("#myCourse-favorite").addClass("active")
      $("#myCourse-favorite").addClass("in")
    }
  }

  $('.wishlist-heart').wishlist();

})(jQuery);