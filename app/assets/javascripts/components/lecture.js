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

}(jQuery));