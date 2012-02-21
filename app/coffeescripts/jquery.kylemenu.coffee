define [
  'jquery'
  'jquery.ui.menu.inputmenu'
  'vendor/jquery.ui.popup-1.9'
  'vendor/jquery.ui.button-1.9'
], ($, _inputmenu, _popup, _button) ->

  $.fn.kyleMenu = (options) ->
    this.each ->
      opts = $.extend(true, {}, $.fn.kyleMenu.defaults, options)
      unless opts.noButton
        $button = $(this).button(opts.buttonOpts)

        # this is to undo the removal of the 'ui-state-active' class that jquery.ui.button
        # does by default on mouse out if the menu is still open
        $button.bind 'mouseleave.button', ->
          $button.addClass('ui-state-active') if $menu.is('.ui-state-open')

      $menu = $(this).next()
                .menu(opts.menuOpts)
                .popup(opts.popupOpts)
                .addClass("ui-kyle-menu use-css-transitions-for-show-hide")
      $menu.bind "menuselect", ->
        $(this).popup('close').removeClass "ui-state-open"

  $.fn.kyleMenu.defaults =
    popupOpts:
      position: { my: 'center top', at: 'center bottom', offset: '0 10px', within: '#main', collision: 'fit' },
      open: (event) ->
        # handle sticking the carat right below where you clicked on the button
        $(this).find(".ui-menu-carat").remove()
        $trigger = $(this).popup("option", "trigger")
        $trigger.addClass('ui-state-active')
        triggerWidth = $trigger.width()
        differenceInOffset = $trigger.offset().left - $(this).offset().left
        actualOffset = event.pageX - $trigger.offset().left
        caratOffset = Math.min(
          Math.max(20, actualOffset),
          triggerWidth - 20
        ) + differenceInOffset
        $('<span class="ui-menu-carat"><span /></span>').css('left', caratOffset).prependTo(this)

        # this, along with the webkit animation makes it bounce into place.
        $(this).css('-webkit-transform-origin-x', caratOffset + 'px').addClass('ui-state-open')
      close: ->
        $(this).popup("option", "trigger").removeClass 'ui-state-active'
        $(this).removeClass "ui-state-open"
    buttonOpts:
      icons: {primary: "ui-icon-home", secondary: "ui-icon-droparrow"}


  # this is a behaviour that will automatically set up a set of .admin-links
  # when the button is clicked, see _admin_links.scss for markup
  $('.al-trigger').live 'click', (event)->
    $this = $(this)
    unless $this.is('.ui-button')
      event.preventDefault()
      $(this).kyleMenu({
        buttonOpts:
          icons: { primary: null, secondary: null }
      }).next().popup('open')

