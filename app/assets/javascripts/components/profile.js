(function($){
	$(document).ready(function() {
		$(".item-link-social>.form-control").each(function() {
      // get width of prelink
      var widthPreLink = $(this).next(".item-text-social").children('.pre-link').width() + 2;
      // css input
      $(this).css("text-indent",widthPreLink + "px");
    });
	});
}(jQuery));