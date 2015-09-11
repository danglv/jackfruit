(function ($) {

  $.fn.selectCardHandle = function () {
    this.click(function () {
      
      $(".phone-cards .selected").removeClass("selected");
      $(this).addClass("selected");
      $(".card-id").val($(this).attr("val"));
    });
  };
  $(".select-card").selectCardHandle();

})(jQuery);