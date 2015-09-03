(function ($) {

   // get param url
  var getParameterByName = function (name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
      results = regex.exec(location.search);
    return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
  };

  // handle detect change filter 
  $.fn.changeFilter = function () {
    this.change( function () {
      var inputChecked = $(this);
      //unchecked other
      $(".filter input[type=checkbox]").each(function () {
        var name = $(this).attr('name');
        var value = $(this).attr('value');
        if (name == inputChecked.attr('name') && inputChecked.attr('value') != value) {
          $(this).removeAttr('checked');
        }
      });
      // make submit form
      $('#filter-form').submit();
    });
  };
  $('.filter input[type=checkbox]').changeFilter();

  // selected with param url
  var budget = getParameterByName("budget");
  var feature = getParameterByName("feature");
  var level = getParameterByName("level");

  $(".filter input[type=checkbox]").each( function () {
    var value = $(this).attr('value');
    if (value == budget || value == feature || value == level) {
      $(this).attr("checked", "checked");
    };
  });


})(jQuery);