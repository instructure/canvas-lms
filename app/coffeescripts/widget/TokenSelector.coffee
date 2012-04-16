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
  'jquery.ajaxJSON'
  'jquery.instructure_misc_helpers'
  'jquery.disableWhileLoading'
  'compiled/jquery/scrollIntoView'
], ($) ->

  class

    constructor: (@input, @url, @options={}) ->
      @stack = []
      @fetchListAjaxRequests = []
      @queryCache = {}
      @$container = $('<div />').addClass('autocomplete_menu')
      @$container.addClass('with-toggles') if @options.showToggles
      @$menu = $('<div />').append(@$list = @newList())
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

    abortRunningRequests: ->
      req.abort() for req in @fetchListAjaxRequests
      @fetchListAjaxRequests = []

    browse: (data) ->
      unless @uiLocked
        @input.val('')
        @close()
        @fetchList(data: data)
        true

    newList: ->
      $list = $('<div class="list"><ul class="heading"></ul><ul></ul></div>')
      $list.find('ul')
        .mousemove (e) =>
          return if @uiLocked
          $li = $(e.target).closest('li')
          $li = null unless $li.hasClass('selectable')
          @select($li)
        .mousedown (e) =>
          # sooper hacky... prevent the menu closing on scrollbar drag
          setTimeout =>
            @input.focus()
          , 0
        .click (e) =>
          return if @uiLocked
          $li = $(e.target).closest('li')
          $li = null unless $li.hasClass('selectable')
          @select($li)
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
      $list.body = $list.find('ul').last()
      $list

    captureKeyDown: (e) ->
      return true if @uiLocked
      switch e.originalEvent?.keyIdentifier ? e.which
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
              @select(@$list.find('li').first())
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
      @fetchList()
      false

    fetchList: (options={}, @uiLocked=false) ->
      clearTimeout @timeout
      @timeout = setTimeout =>
        postData = @preparePost(options.data ? {})
        thisQuery = JSON.stringify(postData)
        if postData.search is '' and not @listExpanded() and not options.data
          @uiLocked = false
          @close()
          return
        if thisQuery is @lastAppliedQuery
          @uiLocked = false
          return
        else if @queryCache[thisQuery]
          @lastAppliedQuery = thisQuery
          @lastSearch = postData.search
          @abortRunningRequests()
          @renderList(@queryCache[thisQuery], options, postData)
          return

        @fetchListAjaxRequests.push @load $.ajaxJSON @url, 'GET', $.extend({}, postData),
          (data) =>
            @queryCache[thisQuery] = data
            if JSON.stringify(@preparePost(options.data ? {})) is thisQuery # i.e. only if it hasn't subsequently changed (and thus triggered another call)
              @lastAppliedQuery = thisQuery
              @lastSearch = postData.search
              @renderList(data, options, postData) if @$menu.is(":visible")
            else
              @uiLocked=false
          ,
          (data) =>
            @uiLocked=false
      , 100

    addByUserId: (userId, fromConversationId) ->
      success = (data) =>
        @close()
        user = data[0]
        if user
          @input.addToken
            value: user.id
            text: user.name
            data: user

      @load $.ajaxJSON( @url, 'GET', { user_id: userId, from_conversation_id: fromConversationId}, success, @close )

    open: ->
      @$container.show()
      @reposition()

    close: =>
      @uiLocked = false
      @$container.hide()
      delete @lastAppliedQuery
      for [$selection, $list, query, search], i in @stack
        @$list.remove()
        @$list = $list.css('height', 'auto')
      @$list.find('ul').html('')
      @stack = []
      @$menu.css('left', 0)
      @select(null)
      @input.selectorClosed()

    clear: ->
      @input.val('')

    blur: ->
      @close()

    listExpanded: ->
      if @stack.length then true else false

    selectionExpanded: ->
      @selection?.hasClass('expanded') ? false

    selectionExpandable: ->
      @selection?.hasClass('expandable') ? false

    selectionToggleable: ($node=@selection) ->
      ($node?.hasClass('toggleable') ? false) and not @selectionExpanded()

    expandSelection: ->
      return false unless @selectionExpandable() and not @selectionExpanded()
      @stack.push [@selection, @$list, @lastAppliedQuery, @lastSearch]
      @clear()
      @$menu.css('width', ((@stack.length + 1) * 100) + '%')
      @fetchList({expand: true}, true)

    collapse: ->
      return false unless @listExpanded()
      [$selection, $list, @lastAppliedQuery, @lastSearch] = @stack.pop()
      @uiLocked = true
      $list.css('height', 'auto')
      @$menu.animate {left: '+=' + @$menu.parent().css('width')}, 'fast', =>
        @input.val(@lastSearch)
        @$list.remove()
        @$list = $list
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
      $list = if offset then @stack[@stack.length - offset][1] else @$list
      $selectAll = $list.selectAll
      return unless $selectAll
      $nodes = $list.body.find('li.toggleable').not($selectAll)
      if selectAllToggled
        if $selectAll.hasClass('on')
          $nodes.addClass('on').each (i, node) =>
            @toggleSelection off, $(node), true
        else
          $nodes.removeClass('on').each (i, node) =>
            @toggleSelection off, $(node), true
      else
        $onNodes = $nodes.filter('.on')
        if $onNodes.length < $nodes.length and $selectAll.hasClass('on')
          $selectAll.removeClass('on')
          @toggleSelection off, $selectAll, true
          $onNodes.each (i, node) =>
            @toggleSelection on, $(node), true
        else if $onNodes.length == $nodes.length and not $selectAll.hasClass('on')
          $selectAll.addClass('on')
          @toggleSelection on, $selectAll, true
          $onNodes.each (i, node) =>
            @toggleSelection off, $(node), true
      if offset < @stack.length
        offset++
        $parentNode = @stack[@stack.length - offset][0]
        if @selectionToggleable($parentNode)
          if $selectAll.hasClass('on')
            $parentNode.addClass('on')
          else
            $parentNode.removeClass('on')
          @updateSelectAll($parentNode, offset)

    select: ($node, preserveMode = false) ->
      return if $node?[0] is @selection?[0]
      @selection?.removeClass('active')
      @selection = if $node?.length
        $node.addClass('active')
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
        @$list.find('li:first')
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
        @$list.find('li:last')
      )
      @selectPrev() if @selection?.hasClass('message')

    populateRow: ($node, data, options={}) ->
      if @options.populator
        @options.populator(this, $node, data, options)
      else
        $node.data('id', data.text)
        $node.text(data.text)
      $node.addClass('first') if options.first
      $node.addClass('last') if options.last

    load: (deferred) ->
      unless @$menu.is(":visible")
        @open()
        @$list.find('ul').last().append($('<li class="message first last"></li>'))
      @$list.disableWhileLoading(deferred)
      deferred

    renderList: (data, options={}, postData={}) ->
      @open()

      if options.expand
        $list = @newList()
      else
        $list = @$list
      $list.selectAll = null

      @selection = null
      $uls = $list.find('ul')
      $uls.html('')
      $heading = $uls.first()
      $body = $uls.last()
      if data.length
        parent = if @stack.length then @stack[@stack.length - 1][0] else null
        ancestors = if @stack.length then (ancestor[0].data('id') for ancestor in @stack) else []
        unless data.prepared
          @options.preparer?(postData, data, parent)
          data.prepared = true

        for row, i in data
          $li = $('<li />').addClass('selectable')
          @populateRow($li, row, level: @stack.length, first: (i is 0), last: (i is data.length - 1), parent: parent, ancestors: ancestors)
          $list.selectAll = $li if row.selectAll
          $li.addClass('on') if $li.hasClass('toggleable') and @input.hasToken($li.data('id'))
          $body.append($li)
        $list.body.find('li.toggleable').addClass('on') if $list.selectAll?.hasClass?('on') or @stack.length and @stack[@stack.length - 1][0].hasClass?('on')
      else
        $message = $('<li class="message first last"></li>')
        $message.text(@options.messages?.noResults ? '')
        $body.append($message)

      if @listExpanded()
        $li = @stack[@stack.length - 1][0].clone()
        $li.addClass('expanded').removeClass('active first last')
        $heading.append($li).show()
      else
        $heading.hide()

      if options.expand
        $list.insertAfter(@$list)
        @$menu.animate {left: '-=' + @$menu.parent().css('width')}, 'fast', =>
          @$list.animate height: '1px', 'fast', =>
            @uiLocked = false
          @$list = $list
          @selectNext(true)
      else
        @selectNext(true) unless options.loading
        @uiLocked = false

    preparePost: (data) ->
      postData = $.extend({}, @options.baseData ? {}, data, {search: @input.val().replace(/^\s+|\s+$/g, "")})
      excludes = @input.baseExclude.concat(if @stack.length then [] else @input.tokenValues())
      postData.exclude = if postData.exclude then postData.exclude.concat excludes else excludes
      postData.context = @stack[@stack.length - 1][0].data('id') if @listExpanded()
      postData.per_page ?= @options.limiter?(level: @stack.length)
      postData

    teardown: ->
      @$container.remove()

