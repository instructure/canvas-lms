(($) ->
  $.fn.kyleMenu = (options) ->
    this.each ->
      opts = $.extend(true, {}, $.fn.kyleMenu.defaults, options)
      $(this).button(opts.buttonOpts) unless opts.noButton
      $menu = $(this).next()
                .menu(opts.menuOpts)
                .popup(opts.popupOpts)
                .addClass("ui-kyle-menu use-css-transitions-for-show-hide")
      $menu.bind "menuselect", -> $(this).removeClass "ui-state-open"

  $.fn.kyleMenu.defaults =
    popupOpts:
      position: { my: 'center top', at: 'center bottom', offset: '0 10px' },
      open: (event) ->
        # handle sticking the carat right below where you clicked on the button
        $(this).find(".ui-menu-carat").remove()
        $trigger = jQUI19(this).popup("option", "trigger")
        triggerWidth = $trigger.width()
        differenceInWidth = $(this).width() - triggerWidth
        actualOffset = event.pageX - $trigger.offset().left
        caratOffset = Math.min(
          Math.max(20, actualOffset),
          triggerWidth - 20
        ) + differenceInWidth/2
        $('<span class="ui-menu-carat"><span /></span>').css('left', caratOffset).prependTo(this)

        # this, along with the webkit animation makes it bounce into place.
        $(this).css('-webkit-transform-origin-x', caratOffset + 'px').addClass('ui-state-open')
      close: ->
        $(this).removeClass "ui-state-open"
    buttonOpts:
      icons: {primary: "ui-icon-home", secondary: "ui-icon-droparrow"}
)(this.jQuery)
