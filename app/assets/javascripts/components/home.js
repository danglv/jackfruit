'use strict';

$(document).ready(function() {
  $('.show-all').click(function(event) {
    event.preventDefault();

    var listCourse = $(this).parent().next().next('.list-course-card');
    if (listCourse.css("overflow")=="visible") {
      $(this).html("Xem tất cả <i class='fa fa-plus-circle'></i>");
      listCourse.css({"height":"310px","overflow":"hidden"});
    }else{
      $(this).html("Thu gọn <i class='fa fa-minus-circle'></i>");
      listCourse.css({"height":"auto","overflow":"visible"});
    }
  });
});