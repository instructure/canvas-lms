#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'jquery'
  'underscore'
  'compiled/widget/TokenSelectorList'
  'compiled/collections/RecipientCollection'
  'jquery.instructure_misc_helpers'
  'compiled/jquery/scrollIntoView'
], ($, _, TokenSelectorList, RecipientCollection) ->

  class

    constructor: (@input, @url, @options={}) ->
      @stack = []
      @cache = {}
      @$container = $('<div />').addClass('autocomplete_menu')
      @$menu = $('<div />')
      @$container.append($('<div />').append(@$menu))
      @$container.css('top', 0).css('left', 0)
      @mode = 'input'
      $('body').append(@$container)

      @reposition = =>
        offset = @input.bottomOffset()
        @$container.css('top', offset.top)
        @$container.css('left', offset.left)
      $(window).resize @reposition
      @close()

    autoSelectFirst: (list=@list) =>
      if list is @list and not @selection?
        @select(list.first(), true)

    browse: (data) ->
      return if @uiLocked
      # prevent pending searches
      @clear()
      @close()
      @open()
      @list = @listForQuery(@preparePost(data))
      @list.appendTo(@$menu)
      @autoSelectFirst()
      true

    mouseMove: (e) =>
      return if @uiLocked
      $li = $(e.target).closest('li')
      $li = null unless $li.hasClass('selectable')
      @select($li)

    mouseDown: (e) =>
      # sooper hacky... prevent the menu closing on scrollbar drag
      setTimeout =>
        @input.focus()
      , 0

    click: (e) =>
      return if @uiLocked
      @mouseMove(e)
      if @selection
        if $(e.target).closest('a.expand').length
          if @selectionExpanded()
            @collapse()
          else
            @expandSelection()
        else if @selectionToggleable() and $(e.target).closest('a.toggle').length
          @toggleSelection()
        else
          if @selectionExpanded()
            @collapse()
          else if @selectionExpandable()
            @expandSelection()
          else
            @toggleSelection(on)
            @clear()
            @close()
      @input.focus()

    captureKeyDown: (e) ->
      keyCode = e.originalEvent?.keyIdentifier ? e.which

      return true if @uiLocked
      if @$menu.find('.no-results').length > 0 and _.include([13, 'Enter'], keyCode)
        return e.preventDefault()

      switch keyCode
        when 'Backspace', 'U+0008', 8
          if @input.val() is ''
            if @listExpanded()
              @collapse()
            else if @$menu.is(":visible")
              @close()
            else
              @input.removeLastToken()
            return true
        when 'Tab', 'U+0009', 9
          if @selection and (@selectionToggleable() or not @selectionExpandable())
            @toggleSelection(on)
          @clear()
          @close()
          return true if @selection
        when 'Enter', 13
          if @selectionExpanded()
            @collapse()
            return true
          else if @selectionExpandable() and not @selectionToggleable()
            @expandSelection()
            return true
          else if @selection
            @toggleSelection(on)
            @clear()
          @close()
          return true
        when 'Shift', 16 # noop, but we don't want to set the mode to input
          return false
        when 'Esc', 'U+001B', 27
          if @$menu.is(":visible")
            @close()
            return true
          else
            return false
        when 'U+0020', 32 # space
          if @selectionToggleable() and @mode is 'menu'
            @toggleSelection()
            return true
        when 'Left', 37
          if @listExpanded() and @input.caret() is 0
            if @selectionExpanded() or @input.val() is ''
              @collapse()
            else
              @select(@list.first())
            return true
        when 'Up', 38
          @selectPrev()
          return true
        when 'Right', 39
          return true if @input.caret() is @input.val().length and @expandSelection()
        when 'Down', 40
          @selectNext()
          return true
        when 'U+002B', 187, 107 # plus
          if @selectionToggleable() and @mode is 'menu'
            @toggleSelection(on)
            return true
        when 'U+002D', 189, 109 # minus
          if @selectionToggleable() and @mode is 'menu'
            @toggleSelection(off)
            return true
      @mode = 'input'
      @updateSearch()
      false

    open: ->
      @$container.show()
      @reposition()

    close: =>
      @uiLocked = false
      @$container.hide()
      @list?.remove()
      for [$selection, list], i in @stack
        list.remove()
      @list = null
      @stack = []
      @$menu.css('left', 0)
      @select(null)
      @input.selectorClosed()

    clear: ->
      clearTimeout @timeout
      @input.val('')
      @select(null)

    blur: ->
      # It seems we can't check focus while it is being changed, so check it later.
      setTimeout =>
        unless @input.hasFocus() || @$container.find(':focus').length > 0
          @close()
      , 0

    listExpanded: ->
      if @stack.length then true else false

    parent: ->
      if @listExpanded() then @stack[@stack.length - 1][0] else null

    selectionExpanded: ->
      @selection?.hasClass('expanded') ? false

    selectionExpandable: ->
      @selection?.hasClass('expandable') ? false

    selectionToggleable: ($node=@selection) ->
      ($node?.hasClass('toggleable') ? false) and not @selectionExpanded()

    expandSelection: ->
      return false unless @selectionExpandable() and not @selectionExpanded()
      @stack.push [@selection, @list]
      @clear()
      @$menu.css('width', ((@stack.length + 1) * 100) + '%')

      @uiLocked = true
      list = @listForQuery(@preparePost())
      list.insertAfter(@list)
      @$menu.animate {left: '-=' + @$menu.parent().css('width')}, 'fast', =>
        @list.hide =>
          @list = list
          @autoSelectFirst()
          @uiLocked = false

    collapse: ->
      return false unless @listExpanded()
      [$selection, list] = @stack.pop()
      @uiLocked = true
      list.restore()
      @$menu.animate {left: '+=' + @$menu.parent().css('width')}, 'fast', =>
        @list.remove()
        @list = list
        @input.val(@list.query.search)
        @select $selection
        @uiLocked = false

    toggleSelection: (state, $node=@selection, toggleOnly=false) ->
      return false unless state? or @selectionToggleable($node)
      id = $node.data('id')
      state = !$node.hasClass('on') unless state?
      if state
        $node.addClass('on') if @selectionToggleable($node) and not toggleOnly
        @input.addToken
          value: id
          text: $node.data('text') ? $node.text()
          noClear: true
          data: $node.data('user_data')
      else
        $node.removeClass('on') unless toggleOnly
        @input.removeToken value: id
      @updateSelectAll($node) unless toggleOnly

    updateSelectAll: ($node, offset=0) ->
      selectAllToggled = $node.data('user_data').selectAll
      list = if offset then @stack[@stack.length - offset][1] else @list
      return unless list.canSelectAll()
      list.updateSelectAll selectAllToggled, (state, $node) =>
        @toggleSelection state, $node, true

      if offset < @stack.length
        offset++
        $parentNode = @stack[@stack.length - offset][0]
        if @selectionToggleable($parentNode)
          if list.selectAllActive()
            $parentNode.addClass('on')
          else
            $parentNode.removeClass('on')
          @updateSelectAll($parentNode, offset)

    select: ($node, preserveMode = false) =>
      return if $node?[0] is @selection?[0]
      @selection = if $node?.length
        $node.focus()
        $node.scrollIntoView(ignore: {border: on})
        $node
      else
        null
      @mode = (if $node then 'menu' else 'input') unless preserveMode

    selectNext: (preserveMode = false) ->
      @select(if @selection
        if @selection.next().length
          @selection.next()
        else if @selection.parent('ul').next().length
          @selection.parent('ul').next().find('li').first()
        else
          null
      else
        @list?.first()
      , preserveMode)
      @selectNext(preserveMode) if @selection?.hasClass('message')

    selectPrev: ->
      @select(if @selection
        if @selection?.prev().length
          @selection.prev()
        else if @selection.parent('ul').prev().length
          @selection.parent('ul').prev().find('li').last()
        else
          null
      else
        @list?.last()
      )
      @selectPrev() if @selection?.hasClass('message')

    updateSearch: ->
      # do it in a timeout both so (1) the triggering keystroke can make it
      # into @input before we try and use it, and (2) a rapid sequence of keys
      # only executes the block once at the end.
      clearTimeout @timeout
      @select(null)
      @timeout = setTimeout =>
        if @lastFetch and !@lastFetch.isResolved()
          @nextRequest = true
          return
        list = @listForQuery(@preparePost())
        if list is @list
          # no change
        else if list.query.search is '' and not @listExpanded()
          # changed to where we don't need the menu open anymore
          @close() if @$menu.is(":visible")
        else
          # activate a new list for the updated search
          if @list
            list.insertAfter(@list)
            @list.remove()
          else
            @open()
            list.appendTo(@$menu)
          @list = list
          @autoSelectFirst()
      , 200

    preparePost: (data) ->
      postData = $.extend({}, @options.baseData ? {}, data ? {}, {search: @input.val().replace(/^\s+|\s+$/g, "")})
      postData.exclude ?= []
      postData.exclude = postData.exclude.concat @input.baseExclude
      if @listExpanded()
        postData.context = @parent().data('id')
      else
        postData.exclude = postData.exclude.concat @input.tokenValues()
      postData

    lastFetch: null
    collectionForQuery: (query) ->
      @lastFetch?.abort()
      cacheKey = JSON.stringify(query)
      unless @cache[cacheKey]?
        collection = new RecipientCollection
        collection.url = @url
        @lastFetch = collection.fetch data: query
        @cache[cacheKey] = collection
      @cache[cacheKey]

    listForQuery: (query) ->
      collection = @collectionForQuery(query)
      list = new TokenSelectorList
        selector: this
        parent: @parent()
        ancestors: (ancestor[0].data('id') for ancestor in @stack)
        collection: collection
        query: query
      list.render()

      unless collection.atLeastOnePageFetched
        collection.on 'fetch', _.once =>
          @autoSelectFirst list
          @updateSearch() if @nextRequest
          delete @nextRequest

      list

    teardown: ->
      @$container.remove()

