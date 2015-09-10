(function ($) {

  $.fn.selectPageHandle = function () {
    this.click(function () {
      var page = $(this).attr("val");
      if( page.trim() != "") {
        $("#page").val(page);
        $("#filter-form").submit();
      }
    });
  };

  $(".pagination .page").selectPageHandle();

})(jQuery);