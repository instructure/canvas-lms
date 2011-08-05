(function() {
  (function($) {
    $.fn.kyleMenu = function(options) {
      return this.each(function() {
        var $menu, opts;
        opts = $.extend(true, {}, $.fn.kyleMenu.defaults, options);
        $menu = $(this).button(opts.buttonOpts).next().menu(opts.menuOpts).popup(opts.popupOpts).addClass("ui-kyle-menu");
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
          var $trigger, caratOffset, differenceInWidth, triggerWidth;
          $(this).find(".ui-menu-carat").remove();
          $trigger = jQUI19(this).popup("option", "trigger");
          triggerWidth = $trigger.width();
          differenceInWidth = $(this).width() - triggerWidth;
          caratOffset = Math.min(Math.max(20, event.offsetX), triggerWidth - 20) + differenceInWidth / 2;
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
