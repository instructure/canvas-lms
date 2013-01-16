define [
  'jquery'
  'Backbone'
], ($, Backbone) ->

  class NavigationView extends Backbone.View

    keyCodes:
      32: 'Space'
      38: 'UpArrow'
      40: 'DownArrow'

    els:
      '#nav_enabled_list' : '$enabled_list'
      '#nav_disabled_list' : '$disabled_list'

    afterRender: ->
      @keyCodes = Object.freeze? @keyCodes
      $("li.navitem").on 'keydown', @onKeyDown

    onKeyDown: (e) =>
      $target = $(e.target)
      fn      = "on#{@keyCodes[e.keyCode]}Key"
      @[fn].call(this, e, $target) and e.preventDefault() if @[fn]

    # Internal: move to the previous element
    # or up to the enabled list if at the top of the disabled list
    # returns nothing
    onUpArrowKey: (e, $target) ->
      prev = $target.prev("li.navitem")

      if @empty(prev)
        prev = $target.children("li.navitem").first()

      if @empty(prev) && @disabled($target)
        prev = @$enabled_list.children("li.navitem").last()

        if @empty(prev)
          prev = @$enabled_list
          prev.attr('tabindex', 0)
          prev.bind 'keydown', @onKeyDown

      prev.focus()

    # Internal: move to the next element
    # or down to the disabled list if at the bottom of the enabled list
    # returns nothing
    onDownArrowKey: (e, $target) ->
      next = $target.next("li.navitem")

      if @empty(next)
        next = $target.children("li.navitem").first()

      if @empty(next) && @enabled($target)
        next = @$disabled_list.children("li.navitem").first()

        if @empty(next)
          next = @$disabled_list
          next.attr('tabindex', -1)
          next.bind 'keydown', @onKeyDown

      next.focus()

    # Internal: mark the current element to begin dragging
    # or drop the current element
    # returns nothing
    onSpaceKey: (e, $target) ->
      if dragObject = @$el.data('drag')
        unless $target.is(dragObject)
          # drop
          if $target.is('li.navitem')
            $target.after(dragObject)
          else
            $target.append(dragObject)
            $target.attr('tabindex', -1)
            $target.unbind('keydown')

          dragObject.attr('aria-grabbed', false)
        @$el.data('drag', null)
        dragObject.focus()
      else if $target.is('li.navitem')
        $target.attr('aria-grabbed', true)
        dragObject = $target
        @$el.data('drag', dragObject)

    # Internal: returns whether the selector is empty
    empty: (selector) ->
      selector.length == 0

    # Internal: returns whether the element is inside the enabled list
    enabled: (el) ->
      el.parent().attr("id") == @$enabled_list.attr("id")

    # Internal: returns whether the element is inside the enabled list
    disabled: (el) ->
      el.parent().attr("id") == @$disabled_list.attr("id")