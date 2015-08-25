(function ($){

  $.fn.sliderDropdown = function (){
    this.click(function (){

      // get pushedContainer and content 
      var pushedContainer = $( $(this).attr("data-pushed-container"));
      var dropdownContainer = $( $(this).attr("data-dropdown-container") );
      //  prepend content into pushedContainer
      dropdownContainer.css({"float":"left"});
      pushedContainer.parent().prepend(dropdownContainer);
      // show or hide slide
      if(dropdownContainer.css("display") == "none"){

        dropdownContainer.css({"margin-left": "-" + dropdownContainer.width() + "px"})
        dropdownContainer.css({"display":"block"});
        dropdownContainer.animate({"margin-left": "0px"},150);
        pushedContainer.animate({"margin-left": (dropdownContainer.width() - 30) + "px"},150);

      }
      else{
        pushedContainer.animate({"margin-left":"0px"},150);
        dropdownContainer.animate({"margin-left": "-" + dropdownContainer.width() + "px"},150);
        dropdownContainer.css({"display":"none"});
      }
      return this;
    });
  }
}(jQuery));