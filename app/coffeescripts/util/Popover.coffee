define [
  'jquery'
], ($) ->


  # you can provide a 'using' option to jqueryUI position
  # it will be passed the position cordinates and a feedback object which,
  # among other things, tells you where it positioned it relative to the target. we use it to add some
  # css classes that handle putting the pointer triangle (aka: caret) back to the trigger.
  using = ( position, feedback ) ->
    $( this )
      .css( position )
      .toggleClass('carat-bottom', feedback.vertical == 'bottom')



  idCounter = 0
  activePopovers = []

  class Popover
    constructor: (clickEvent, @content, @options = {}) ->
      @trigger = $(clickEvent.currentTarget)
      @el = $(@content)
              .addClass('carat-bottom')
              .data('popover', this)
              .keydown (event) =>
                # if the user hits the escape key, reset the focus to what it was.
                if event.keyCode is $.ui.keyCode.ESCAPE
                  @hide()
                # If the user tabs or shift-tabs away, close.
                return unless event.keyCode is $.ui.keyCode.TAB
                tabbables = $ ":tabbable", @el
                index = $.inArray event.target, tabbables
                return if index == -1

                if event.shiftKey
                  @hide() if index == 0
                else
                  @hide() if index == tabbables.length-1

      @el.delegate '.popover_close', 'keyclick click', (event) =>
        event.preventDefault()
        @hide()

      @show(clickEvent)

    show: (clickEvent) ->
      popoverToHide.hide() while popoverToHide = activePopovers.pop()
      activePopovers.push(this)
      id = "popover-#{idCounter++}"
      @trigger.attr
        "aria-expanded" : true
        "aria-controls" : id
      @previousTarget = clickEvent.currentTarget

      @el
        .attr(
          'id' : id
        )
        .appendTo(document.body)
        .show()
      @position()
      @el.find(':tabbable').first().focus()
      setTimeout(
        () =>
          @el.find(':tabbable').first().focus()
        , 100
      )

      # handle sticking the carat right above where you clicked on the button, bounded by the dialog
      @el.find(".ui-menu-carat").remove()
      differenceInOffset = @trigger.offset().left - @el.offset().left
      actualOffset = clickEvent.pageX - @trigger.offset().left
      leftBound = Math.max(0, @trigger.width() / 2 - @el.width() / 2) + 20
      rightBound = @trigger.width() - leftBound
      caratOffset = Math.min(Math.max(leftBound, actualOffset), rightBound) + differenceInOffset
      $('<span class="ui-menu-carat"><span /></span>').css('left', caratOffset).prependTo(@el)

      @positionInterval = setInterval @position, 200
      $(window).click @outsideClickHandler

    hide: ->
      # remove this from the activePopovers array
      for popover, index in activePopovers
        activePopovers.splice(index, 1) if this is popover

      @el.detach()
      @trigger.attr 'aria-expanded', false
      clearInterval @positionInterval
      $(window).unbind 'click', @outsideClickHandler
      @restoreFocus()

    ignoreOutsideClickSelector: '.ui-dialog'

    # uses a fat arrow so that it has a unique guid per-instance for jquery event unbinding
    outsideClickHandler: (event) =>
      unless $(event.target).closest(@el.add(@trigger).add(@ignoreOutsideClickSelector)).length
        @hide()

    position: =>
      @el.position
        my: 'center '+(if @options.verticalSide == 'bottom' then 'top' else 'bottom'),
        at: 'center '+(@options.verticalSide || 'top'),
        of: @trigger,
        offset: '0 -10px',
        within: 'body',
        collision: 'flipfit '+(if @options.verticalSide then 'none' else 'flipfit')
        using: using

    restoreFocus: ->
      # set focus back to the previously focused item.
      @previousTarget.focus() if @previousTarget and $(@previousTarget).is(':visible')
