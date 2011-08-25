(function() {
  (function($) {
    $.fn.kyleMenu = function(options) {
      return this.each(function() {
        var $menu, opts;
        opts = $.extend(true, {}, $.fn.kyleMenu.defaults, options);
        if (!opts.noButton) {
          $(this).button(opts.buttonOpts);
        }
        $menu = $(this).next().menu(opts.menuOpts).popup(opts.popupOpts).addClass("ui-kyle-menu use-css-transitions-for-show-hide");
        return $menu.bind("menuselect", function() {
          return $(this).removeClass("ui-state-open");
        });
      });
    };
    return $.fn.kyleMenu.defaults = {
      popupOpts: {
        position: {
          my: 'center top',
          at: 'center bottom',
          offset: '0 10px'
        },
        open: function(event) {
          var $trigger, actualOffset, caratOffset, differenceInWidth, triggerWidth;
          $(this).find(".ui-menu-carat").remove();
          $trigger = $(this).popup("option", "trigger");
          triggerWidth = $trigger.width();
          differenceInWidth = $(this).width() - triggerWidth;
          actualOffset = event.pageX - $trigger.offset().left;
          caratOffset = Math.min(Math.max(20, actualOffset), triggerWidth - 20) + differenceInWidth / 2;
          $('<span class="ui-menu-carat"><span /></span>').css('left', caratOffset).prependTo(this);
          return $(this).css('-webkit-transform-origin-x', caratOffset + 'px').addClass('ui-state-open');
        },
        close: function() {
          return $(this).removeClass("ui-state-open");
        }
      },
      buttonOpts: {
        icons: {
          primary: "ui-icon-home",
          secondary: "ui-icon-droparrow"
        }
      }
    };
  })(this.jQuery);
}).call(this);
