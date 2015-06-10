define [
  'jquery'
  'compiled/util/objectCollection'
  'jst/courseList/wrapper'
  'jst/courseList/content'
  'jquery.ajaxJSON'
], (jQuery, objectCollection, wrapper, content) ->

  class CustomList
    options:
      animationDuration: 200
      dataAttribute: 'id'
      wrapper: wrapper
      content: content
      url: '/api/v1/users/self/favorites/courses'
      appendTarget: 'body',
      resetCount: 12
      onToggle: false

    constructor: (selector, items, options) ->
      @options          = jQuery.extend {}, @options, options
      @appendTarget     = jQuery @options.appendTarget
      @element          = jQuery selector
      @targetList       = @element.find '> ul'
      @wrapper          = jQuery @options.wrapper({})
      @sourceList       = @wrapper.find '> ul'
      @contentTemplate  = @options.content
      @ghost            = jQuery('<ul/>').addClass('customListGhost')
      @requests         = { add: {}, remove: {} }
      @doc              = jQuery document.body

      @attach()
      @setItems items
      @open() if @options.autoOpen

    open: (e) ->
      e.preventDefault() if e
      @wrapper.appendTo(@appendTarget).show()
      setTimeout => # css3 animation
        @element.addClass('customListEditing')
        @options.onToggle?(on)
        document.activeElement.blur()
        @wrapper.find('li a').first().focus()
      , 1
      @element.find('.customListOpen').attr('aria-expanded': 'true')

    close: (e) ->
      e.preventDefault() if e
      @wrapper.hide()
      @element.removeClass('customListEditing')
      @options.onToggle?(off)
      @resetList() if @pinned.length is 0
      document.activeElement.blur()
      @element.find('.customListOpen').focus().attr('aria-expanded': 'false')

    attach: ->
      @element.delegate '.customListOpen', 'click', jQuery.proxy(this, 'open')
      @wrapper.delegate '.customListClose', 'click', jQuery.proxy(this, 'close')
      @wrapper.delegate '.customListRestore', 'click', jQuery.proxy(this, 'reset')
      @wrapper.delegate 'a', 'click.customListTeardown', (event) ->
        event.preventDefault()
      @wrapper.delegate(
        '.customListItem',
        'click.customListTeardown',
        jQuery.proxy(this, 'sourceClickHandler')
      )
      id = 'customListWrapper-'+jQuery.guid++
      @wrapper.appendTo(@appendTarget).attr(id: id).hide()
      @element.find('.customListOpen').attr(role: 'button', 'aria-expanded': 'false', 'aria-controls': id)

    setOn: (element, bool) ->
      element.toggleClass 'on', bool
      element.find('a').attr('aria-checked', bool.toString())

    add: (id, element) ->
      item          = @items.findBy('id', id)
      clone         = element.clone().hide()
      item.element  = clone

      @setOn(element, true)

      @pinned.push item
      @pinned.sortBy('shortName')

      index = @pinned.indexOf(item) + 1
      target = @targetList.find("li:nth-child(#{index})")

      if target.length isnt 0
        clone.insertBefore target
      else
        clone.appendTo @targetList

      clone.slideDown @options.animationDuration
      @animateGhost element, clone
      @onAdd item

    animateGhost: (fromElement, toElement) ->
      from          = fromElement.offset()
      to            = toElement.offset()
      $clone        = fromElement.clone()
      from.position = 'absolute'

      @ghost.append($clone)
      @ghost.appendTo(@doc).css(from).animate to, @options.animationDuration, =>
        @ghost.detach().empty()

    remove: (item, element) ->
      @setOn(element, false)
      @animating = true
      @onRemove item
      item.element.slideUp @options.animationDuration, =>
        item.element.remove()
        @pinned.eraseBy 'id', item.id
        @animating = false

    abortAll: ->
      req.abort() for id, req of @requests.add
      req.abort() for id, req of @requests.remove

    reset: ->
      @abortAll()

      callback = =>
        delete @requests.reset

      @requests.reset = jQuery.ajaxJSON(@options.url, 'DELETE', {}, callback, callback)
      @resetList()

    resetList: ->
      defaultItems = @items.slice 0, @options.resetCount
      html = @contentTemplate items: defaultItems
      @targetList.empty().html(html)
      @setPinned()

    onAdd: (item) ->
      if @requests.remove[item.id]
        @requests.remove[item.id].abort()
        return

      success = =>
        args = [].slice.call arguments
        args.unshift(item.id)
        @addSuccess.apply(this, args)

      error = =>
        args = [].slice.call arguments
        args.unshift(item.id)
        @addError.apply(this, args)

      url = @options.url + '/' + item.id
      req = jQuery.ajaxJSON(url, 'POST', {}, success, error)

      @requests.add[item.id] = req

    onRemove: (item) ->
      if @requests.add[item.id]
        @requests.add[item.id].abort();
        return

      success = =>
        args = [].slice.call arguments
        args.unshift(item.id)
        @removeSuccess.apply(this, args)

      error = =>
        args = [].slice.call arguments
        args.unshift(item.id)
        @removeError.apply(this, args)

      url = @options.url + '/' + item.id
      req = jQuery.ajaxJSON(url, 'DELETE', {}, success, error)

      @requests.remove[item.id] = req

    addSuccess: (id) ->
      delete @requests.add[id]

    addError: (id) ->
      delete @requests.add[id]

    removeSuccess: (id) ->
      delete @requests.remove[id]

    removeError: (id) ->
      delete @requests.remove[id]

    setItems: (items) ->
      @items  = objectCollection items
      @items.sortBy 'shortName'
      html    = @contentTemplate items: @items
      @sourceList.html html
      @setPinned()

    setPinned: ->
      @pinned = objectCollection []

      @element.find('> ul > li').each (index, element) =>
        element = jQuery element
        id      = element.data('id')
        id      = id && String id
        item    = @items.findBy('id', id)

        return unless item
        item.element = element
        @pinned.push item

      @setOn(@wrapper.find('ul > li'), false)

      for item in @pinned
        match = @wrapper.find("ul > li[data-id=#{item.id}]")
        @setOn(match, true)

    sourceClickHandler: (event) ->
      @checkElement jQuery event.currentTarget

    checkElement: (element) ->
      # DOM and data get out of sync for atomic clicking, hence @animating
      return if @animating or @requests.reset
      id = element.data 'id'
      id = id && String id
      item = @pinned.findBy 'id', id

      if item
        @remove item, element
      else
        @add id, element

