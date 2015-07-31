$(document).ready(function () {

  // make submit form
  $('input[type=checkbox]').change(function () {
    var inputChecked = $(this);
    //unchecked other
    $("input[type=checkbox]").each(function () {
      var name = $(this).attr('name');
      var value = $(this).attr('value');
      if (name == inputChecked.attr('name') && inputChecked.attr('value') != value) {
        $(this).removeAttr('checked');
      }
    });
    $('#page-index').val(1);
    $('#test-form').submit();
  });

  // listen sort event
  $('#sorting-options').on('change', function () {
    $('#sorting').val($(this).val());
    $('#test-form').submit();
  });

  // get param url
  function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
      results = regex.exec(location.search);
    return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
  }
  // checked for input of page
  var price = getParameterByName('budget');
  var language = getParameterByName('lang')
  var level = getParameterByName('level');
  var sort = getParameterByName('ordering');
  var page = getParameterByName('page');
  var q = getParameterByName('q');
  $('#page-search').val(q);
  $("input[type=checkbox]").each(function () {
    var value = $(this).attr('value');
    if (value == price || value == language || value == level) {
      $(this).attr("checked", "checked");
    }
  });
  // set selected
  $('option').each(function () {
    if ($(this).val() == sort) {
      $(this).attr("selected", "selected");
      $('select').material_select();
    }
  });
  // set pageginate
  if (page == '') {
    page = '1';
  }

  //preview click

  $("#page-index").val(page);
  $('.pagination li').each(function () {
    if ($(this).text() == page) {
      $(this).addClass('active');
    } else {
      $(this).removeClass('active')
    }
  });
  //listen click into page
  $('.page').click(function (e) {
    $("#page-index").val($(this).text());
    $('#test-form').submit();  
  });

  $('#pre_page').click(function(event) {
    $("#page-index").val(parseInt(page)-1);
    $('#test-form').submit();
  });

  $('#next_page').click(function(event) {
    $("#page-index").val(parseInt(page) + 1);
    $('#test-form').submit();
  });
  
})