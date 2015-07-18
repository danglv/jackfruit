$(document).ready(function () {
  $("#search-form").on("submit", function (e) {
    var input = $("#course-search").val();
    if (input.length < 3) {
      e.preventDefault();
    }
  });
});