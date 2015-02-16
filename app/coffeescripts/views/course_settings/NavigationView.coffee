define [
  'jquery'
  'Backbone'
  'str/htmlEscape'
], ($, Backbone, htmlEscape) ->
  ###
  xsslint jqueryObject.identifier dragObject current_item
  ###

  class NavigationView extends Backbone.View

    keyCodes:
      32: 'Space'
      38: 'UpArrow'
      40: 'DownArrow'

    events:
      'click .disable_nav_item_link': 'disableNavLink'
      'click .move_nav_item_link'   : 'moveNavLink'
      'click .enable_nav_item_link' : 'enableNavLink'


    els:
      '#nav_enabled_list' : '$enabled_list'
      '#nav_disabled_list' : '$disabled_list'
      '#move_nav_item_form': '$move_dialog'
      '.navitem' : '$navitems'
      '#move_nav_item_name' : '$move_name'

    disableNavLink: (e) ->
      $targetItem = $(e.currentTarget).closest('.navitem')
      @$disabled_list.append($targetItem)
      $(e.currentTarget)
        .attr('class', '')
        .attr('class', 'icon-plus enable_nav_item_link')
        .text("Enable")

    enableNavLink: (e) ->
      $targetItem = $(e.currentTarget).closest('.navitem')
      @$enabled_list.append($targetItem)
      $(e.currentTarget)
        .attr('class', '')
        .attr('class', 'icon-x disable_nav_item_link')
        .text("Disable")

    moveNavLink: (e) ->
      dialog = @$move_dialog
      which_list = $(e.currentTarget).closest '.nav_list'
      which_item = $(e.currentTarget).closest '.navitem'
      options = []
      which_list.children('.navitem').each (key, item) ->
        if $(item).attr('aria-label') is which_item.attr('aria-label')
          return
        options.push('<option value="' + htmlEscape($(item).attr('id')) + '">' + htmlEscape($(item).attr('aria-label')) + '</option>')
      $select = @$move_dialog.children().find('#move_nav_item_select')
      # Clear the options first
      $select.empty()
      $select.append($.raw(options.join('')))
      # Set the name in the dialog
      @$move_name.text which_item.attr('aria-label')
      @$move_dialog.data 'current_item', which_item


      @$move_dialog.dialog(
        modal: true
        width: 600
        height: 300
        close: ->
          dialog.dialog('close')
        )

    moveSubmit: (e) ->
      e.preventDefault()
      current_item = $('#move_nav_item_form').data 'current_item'
      before_or_after = $('[name="move_location"]:checked').val();
      selected_item = $('#' + $('#move_nav_item_select').val());
      if before_or_after is 'before'
        selected_item.before current_item
      if before_or_after is 'after'
        selected_item.after current_item
      $('#move_nav_item_form').dialog('close')
      current_item.focus()

    cancelMove: ->
      $('#move_nav_item_form').dialog('close')

    focusKeyboardHelp: (e) ->
      $('.drag_and_drop_warning').removeClass('screenreader-only')

    hideKeyboardHelp: (e) ->
      $('.drag_and_drop_warning').addClass('screenreader-only')

    afterRender: ->
      @keyCodes = Object.freeze? @keyCodes
      $("li.navitem").on 'keydown', @onKeyDown
      $('#move_nav_item_cancel_btn').on 'click', @cancelMove
      @$move_dialog.on 'submit', @moveSubmit
      $('#navigation_tab').on 'blur', @focusKeyboardHelp
      $('.drag_and_drop_warning').on 'blur', @hideKeyboardHelp

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
        dragObject.blur()
        dragObject.focus()

    # Internal: returns whether the selector is empty
    empty: (selector) ->
      selector.length == 0

    # Internal: returns whether the element is inside the enabled list
    enabled: (el) ->
      el.parent().attr("id") == @$enabled_list.attr("id")

    # Internal: returns whether the element is inside the enabled list
    disabled: (el) ->
      el.parent().attr("id") == @$disabled_list.attr("id")
