(function ($) {
  'use strict';

  $.fn.sliderDropdown = function () {
    var ANIMATED_DURATION = 200;
    var activator = this;

    function dropdownContainerCloseAnimationHandler(dropdownContainer) {
      dropdownContainer.animate({
        'margin-left': '-' + dropdownContainer.width() + 'px',
      }, {
        'duration': ANIMATED_DURATION,
        'done': function () {
          activator.parent().removeClass('open');
        }
      });

      dropdownContainer.removeClass('open');
    }

    function dropdownContainerOpenAnimationHandler(dropdownContainer) {
      dropdownContainer.animate({
        'margin-left': '0px'
      }, {
        'duration': ANIMATED_DURATION,
        'done': function () {
          activator.parent().addClass('open');
          activator.parent().find('.dropdown-backdrop').click(function () {
            dropdownContainerCloseAnimationHandler(dropdownContainer);
          });
        }
      });
    }

    this.click(function () {
      // get pushedContainer and content 
      var dropdownContainer = $($(this).attr('data-dropdown-container'));

      // show or hide slide
      var isOpen = activator.parent().attr('class').indexOf('open') >= 0;

      if (isOpen) {
        dropdownContainerCloseAnimationHandler(dropdownContainer);
      } else {
        dropdownContainerOpenAnimationHandler(dropdownContainer);
      }
    });

    return this;
  };
}(jQuery));