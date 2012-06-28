define [
  'jquery'
  'jquery.ui.menu.inputmenu'
  'vendor/jquery.ui.popup-1.9'
  'vendor/jquery.ui.button-1.9'
], ($, _inputmenu, _popup, _button) ->

  class KyleMenu
    constructor: (trigger, options) ->
      @$trigger = $(trigger).data('kyleMenu', this)
      @opts = $.extend(true, {}, KyleMenu.defaults, options)

      unless @opts.noButton
        @$trigger.button(@opts.buttonOpts)

        # this is to undo the removal of the 'ui-state-active' class that jquery.ui.button
        # does by default on mouse out if the menu is still open
        @$trigger.bind 'mouseleave.button', @keepButtonActive

      @$menu = @$trigger.next()
                .menu(@opts.menuOpts)
                .popup(@opts.popupOpts)
                .addClass("ui-kyle-menu use-css-transitions-for-show-hide")

      # passing an appendMenuTo option when initializing a kylemenu helps get aroud popup being hidden
      # by overflow:scroll on its parents
      # but by doing so we need to make sure that click events still get propigated up in case we
      # were delegating events to a parent container
      if @opts.appendMenuTo
        popupInstance = @$menu.data('popup')
        _open = popupInstance.open
        self = this
        # monkey patch just this plugin instance not $.ui.popup.prototype.open
        popupInstance.open = ->
          self.$menu.appendTo(self.opts.appendMenuTo)
          _open.apply(this, arguments)

        @$placeholder = $('<span style="display:none;">').insertAfter(@$menu)
        @$menu.bind 'click', => @$placeholder.trigger arguments...

      @$menu.bind
        menuselect: @close
        popupopen: @onOpen
        popupclose: @onClose

    onOpen: (event) =>
      @adjustCarat event
      @$menu.addClass 'ui-state-open'

    open: ->
      @$menu.popup 'open'

    close: =>
      @$menu.popup('close').removeClass "ui-state-open"

    onClose: =>
      @$menu.insertBefore(@$placeholder) if @opts.appendMenuTo
      @$trigger.removeClass 'ui-state-active'
      @$menu.removeClass "ui-state-open"

    keepButtonActive: =>
      @$trigger.addClass('ui-state-active') if @$menu.is('.ui-state-open')

    # handle sticking the carat right below where you clicked on the button
    adjustCarat: (event) ->
      @$carat?.remove()
      @$trigger.addClass('ui-state-active')
      triggerWidth = @$trigger.outerWidth()
      triggerOffsetLeft = @$trigger.offset().left

      # if it is a mouse event, it will have a 'pageX' otherwise use the middle of the trigger
      pointToDropDownFrom = event.pageX || (triggerOffsetLeft + triggerWidth/2)
      differenceInOffset = triggerOffsetLeft - @$menu.offset().left
      actualOffset = pointToDropDownFrom - @$trigger.offset().left
      caratOffset = Math.min(
        Math.max(6, actualOffset),
        triggerWidth - 6
      ) + differenceInOffset
      @$carat = $('<span class="ui-menu-carat"><span /></span>')
                    .css('left', caratOffset)
                    .prependTo(@$menu)

      # this, along with the webkit animation makes it bounce into place.
      @$menu.css('-webkit-transform-origin-x', caratOffset + 'px')

    @defaults =
      popupOpts:
        position:
          my: 'center top'
          at: 'center bottom'
          offset: '0 10px',
          within: '#main',
          collision: 'fit'
      buttonOpts:
        icons:
          primary: "ui-icon-home"
          secondary: "ui-icon-droparrow"


  #expose jQuery plugin
  $.fn.kyleMenu = (options) ->
    this.each ->
      new KyleMenu(this, options) unless $(this).data().kyleMenu

  return KyleMenu
