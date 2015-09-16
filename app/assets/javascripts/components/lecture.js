(function ($) {
 
 $.fn.fullScreen = function () {

  this.click(function () {
    if( $(this).hasClass("rotate") ) {
  
      $(this).removeClass("rotate");
      var container = $(".lecture").width();
      var widthPlayer = 0;
      var widthContainer = 0;
      if (container >1200){
        widthPlayer = 75;
        widthContainer = 25;
      }
      else if (container > 992){
        widthPlayer = 66.66666666666666;
        widthContainer = 33.33333333333334;
      }
      else if (container > 776){
        widthPlayer = 58.333333333333336;
        widthContainer = 41.666666666666664;
      }
      $(".lecture-player").animate({"width" : widthPlayer + "%"},500);
      $(".lecture-container").animate({"display" : "block"},500);

      // bind event resize
      $( window ).bind("resize", function (){
        $(".lecture-player").attr("style","");
        $( window ).unbind("resize");
        console.log("resized")
      })

    }
    else {
      $(this).addClass("rotate");
      $(".lecture-player").animate({"width" : "100%"},500);
      $(".lecture-container").animate({"display" : "none"},500);

    }
  });
 }
 $(".full-screen").fullScreen();

 $('#lecture-discussion-submit').click(function () {
    var course_id = $("#course_id").val();
    var title = $("#discussion-title").val();
    var description = $("#discussion-content").val();
    var curriculum_id = $("#lecture_id").val();

    var params = {
      'title' : title,
      'description' : description,
      'course_id' : course_id,
      'curriculum_id' : curriculum_id
    }

    var URL = 'http://' + window.location.host + '/courses/' + course_id + '/add_discussion';
    $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function(msg){
          console.log(msg)
        }
      });
  })

}(jQuery));