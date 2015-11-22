(function ($) {

   // get param url
  var getParameterByName = function (name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
      results = regex.exec(location.search);
    return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
  };
  // set default sort
  var sorting = getParameterByName( "sorting" );
  if ( sorting.trim() != "" ){
    $( "#sorting" ).val(sorting);
    var selected = $( ".courses-sorting-select[value=" + sorting + "]" );
    $( ".courses-sorting-selected" ).html(selected.text()+"<b class=\"caret\"></b>");
  }

  $.fn.coursesSortingSelect = function () {
    this.click(function () { 
      $( "#sorting" ).val($(this).attr( "value" ));
      $( "#filter-form" ).submit();
    });
  }
  $(".courses-sorting-select").coursesSortingSelect();

})(jQuery);