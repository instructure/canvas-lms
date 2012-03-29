define [
  'jquery'
  'jquery.ui.menu.inputmenu'
  'vendor/jquery.ui.popup-1.9'
  'vendor/jquery.ui.button-1.9'
], ($, _inputmenu, _popup, _button) ->

  $.fn.kyleMenu = (options) ->
    this.each ->
      opts = $.extend(true, {}, $.fn.kyleMenu.defaults, options)
      $trigger = $(this)
      unless opts.noButton
        $trigger.button(opts.buttonOpts)

        # this is to undo the removal of the 'ui-state-active' class that jquery.ui.button
        # does by default on mouse out if the menu is still open
        $trigger.bind 'mouseleave.button', ->
          $trigger.addClass('ui-state-active') if $menu.is('.ui-state-open')

      $menu = $trigger.next()
                .menu(opts.menuOpts)
                .popup(opts.popupOpts)
                .addClass("ui-kyle-menu use-css-transitions-for-show-hide")

      # passing an appendMenuTo option when initializing a kylemenu helps get aroud popup being hidden
      # by overflow:scroll on its parents
      appendTo = opts.appendMenuTo
      $menu.appendTo(appendTo) if appendTo

      $trigger.data('kyleMenu', $menu)
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
        triggerWidth = $trigger.outerWidth()
        differenceInOffset = $trigger.offset().left - $(this).offset().left
        actualOffset = event.pageX - $trigger.offset().left
        caratOffset = Math.min(
          Math.max(6, actualOffset),
          triggerWidth - 6
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
    $trigger = $(this)
    unless $trigger.is('.ui-button')
      event.preventDefault()

      defaults =
        buttonOpts:
          icons:
            primary: null
            secondary: null
      opts = $.extend defaults, $trigger.data('kyleMenuOptions')

      $trigger.kyleMenu(opts)
      $trigger.data('kyleMenu').popup('open')

