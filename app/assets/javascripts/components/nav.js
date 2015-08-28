(function ($) {

  $.fn.sliderDropdown = function () {
    var activator = this;

    this.click(function () {

      // get pushedContainer and content 
      var dropdownContainer = $($(this).attr("data-dropdown-container"));
      //  prepend content into pushedContainer
      dropdownContainer.css({
        "float": "left"
      });
      // show or hide slide
      var isOpen = activator.parent().attr('class').indexOf('open') >= 0;

      if (isOpen) {
        dropdownContainer.animate({
          "margin-left": "-" + dropdownContainer.width() + "px",
        }, {
          "duration": 200,
          "done": function () {
            activator.parent().removeClass('open');
          }
        });

        dropdownContainer.removeClass('open');
      } else {
        dropdownContainer.animate({
          "margin-left": "0px"
        }, {
          "duration": 200,
          "done": function () {
            activator.parent().addClass('open');
            activator.parent().find('.dropdown-backdrop').click(function () {
              dropdownContainer.animate({
                "margin-left": "-" + dropdownContainer.width() + "px",
              }, {
                "duration": 200,
                "done": function () {
                  activator.parent().removeClass('open');
                }
              });

              dropdownContainer.removeClass('open');
            });
          }
        });
      }
    });

    return this;
  };
}(jQuery));