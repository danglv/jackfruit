(function ($) {
  'use strict';

  $.fn.sliderDropdown = function () {
    var ANIMATED_DURATION = 200;
    var activator = this;

    var isFixed = (activator.attr('data-fixed') === 'true');

    if (isFixed) {
      activator.parent().on({
        'shown.bs.dropdown': function () {
          this.closable = false;
        },
        'click': function () {
          this.closable = true;
        },
        'hide.bs.dropdown': function () {
          return this.closable;
        }
      });

      activator.click();
    }

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

    activator.click(function (e) {
      // get pushedContainer and content 
      var dropdownContainer = $($(this).attr('data-dropdown-container'));
      activator = $(e.target).parent();

      activator.parent().on({
        'hide.bs.dropdown': function () {
          if (activator.parent().css('display') === 'none') {
            dropdownContainerCloseAnimationHandler(dropdownContainer);
          }
        }
      });

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