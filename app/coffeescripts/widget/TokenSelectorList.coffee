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
  'compiled/views/PaginatedView'
  'jquery.disableWhileLoading'
], ($, _, PaginatedView) ->

  class TokenSelectorList extends PaginatedView
    tagName: 'div'
    className: 'list'

    paginationLoaderTemplate: -> """
      <div class="pagination-loader" style="height: 60px;">&nbsp;</div>
    """

    events:
      'blur li'    : 'onBlur'
      'focus li'   : 'onFocus'
      'keydown li': 'onKeydown'

    keyCodes:
      13: 'Enter'
      16: 'Shift'
      17: 'Control'
      18: 'Alt'
      27: 'Escape'
      32: 'Space'
      37: 'LeftArrow'
      38: 'UpArrow'
      39: 'RightArrow'
      40: 'DownArrow'
      91: 'Command'

    initialize: (options) ->
      @paginationScrollContainer = $('<ul />', role: 'menu')
      super
      @selector = @options.selector
      @parent = @options.parent
      @ancestors = @options.ancestors
      @query = @options.query

      @$heading                  = $('<ul />', class: 'heading').appendTo(@$el)
      @$body                     = @paginationScrollContainer.appendTo(@$el)

      @$el.find('ul')
        .on('mousemove', @selector.mouseMove)
        .on('mousedown', @selector.mouseDown)
        .on('click', @selector.click)

      @collection.on 'beforeFetch', @showPaginationLoader, this
      @collection.on 'fetch', @render

    render: =>
      activeIndex = @paginationScrollContainer.children('.active').index()
      @clear()
      @$selectAll = null

      if @parent
        $li = @parent.clone()
        $li.addClass('expanded').removeClass('active first last')
        @$heading.append($li).show()
      else
        @$heading.hide()

      unless @query.search
        if @collection.length > 0
          filterText = @selector.options.includeFilterOption?(@query)
          @addFilterOption(filterText) if filterText
        if @collection.length > 1
          everyoneText = @selector.options.includeEveryoneOption?(@query, @parent)
          selectAllText = @selector.options.includeSelectAllOption?(@query, @parent)
          @addEveryoneOption(everyoneText) if everyoneText
          @addSelectAllOption(selectAllText) if selectAllText
      @collection.each @addOne
      @$body.find('li.toggleable').addClass('on') if @selectAllActive() or @parent?.hasClass?('on')
      @$el.toggleClass('with-toggles', @selector.options.showToggles and @$body.find('li.toggleable').length > 0)
      @selector.select($(@paginationScrollContainer.children()[activeIndex]))

      if @collection.fetchingPage or @collection.fetchingNextPage
        @showPaginationLoader()
      else
        @hidePaginationLoader()

      if @collection.atLeastOnePageFetched and not @$body.find('li').length
        $message = $('<li class="message first last no-results"></li>')
        $message.text(@selector.options.messages?.noResults ? '')
        @$body.append($message)

      super

    addEveryoneOption: (everyoneText) ->
      parentData = @parent.data('user_data')
      row =
        id: "#{@query.context}_all"
        name: everyoneText
        user_count: parentData.user_count
        type: 'context'
        avatar_url: parentData.avatar_url
      if @selector.options.includeSelectAllOption
        $.extend row,
          permissions: parentData.permissions
          selectAll: parentData.permissions.send_messages_all
      @addOneRaw row

    addSelectAllOption: (selectAllText) ->
      parentData = @parent.data('user_data')
      @addOneRaw
        id: @query.context
        name: selectAllText
        user_count: parentData.user_count
        type: 'context'
        avatar_url: parentData.avatar_url
        permissions: parentData.permissions
        selectAll: true
        noExpand: true # just a magic select-all checkbox, you can't drill into it

    addFilterOption: (filterText) ->
      @addOneRaw
        id: @query.context
        name: @parent.data('text')
        type: 'context'
        avatar_url: @parent.data('user_data').avatar_url
        subText: filterText
        noExpand: true

    addOne: (recipient) =>
      @addOneRaw(recipient.attributes)

    addOneRaw: (row) ->
      $li = $('<li />', class: 'selectable', tabindex: '-1')
      $li.addClass('first') unless @$body.find('li:first')
      @$body.find('li:last').removeClass('last')
      $li.addClass('last')

      @populateRow($li, row, level: @ancestors.length, parent: @parent, ancestors: @ancestors)
      @$selectAll = $li if row.selectAll
      $li.addClass('on') if $li.hasClass('toggleable') and @selector.input.hasToken($li.data('id'))
      @$body.append($li)

    populateRow: ($node, data, options={}) ->
      if @selector.options.populator
        options = $.extend { noExpand: @selector.options.noExpand }, options
        @selector.options.populator(@selector, $node, data, options)
      else
        $node.data('id', data.text)
        $node.text(data.text)

    first: ->
      @$el.find('li:first')

    last: ->
      @$el.find('li:last')

    appendTo: ($node) ->
      $node.append(@$el)

    insertAfter: (otherList) ->
      @$el.insertAfter(otherList.$el)

    remove: ->
      @$el.remove()

    hide: (callback) ->
      @$el.animate height: '1px', 'fast', callback

    restore: ->
      @$el.css('height', 'auto')

    clear: ->
      @$body.empty()
      @$heading.empty()

    showPaginationLoader: =>
      rv = super
      @$paginationLoader.disableWhileLoading(@collection.deferred)
      rv

    placePaginationLoader: ->
      @$paginationLoader?.insertAfter @$body

    canSelectAll: ->
      @$selectAll?

    selectAllActive: ->
      @$selectAll?.hasClass('on')

    updateSelectAll: (selectAllToggled, toggle) ->
      return unless @$selectAll
      $nodes = @$body.find('li.toggleable').not(@$selectAll)
      if selectAllToggled
        if @selectAllActive()
          $nodes.addClass('on').each (i, node) =>
            toggle off, $(node)
        else
          $nodes.removeClass('on').each (i, node) =>
            toggle off, $(node)
      else
        $onNodes = $nodes.filter('.on')
        if $onNodes.length < $nodes.length and @selectAllActive()
          @$selectAll.removeClass('on')
          toggle off, @$selectAll
          $onNodes.each (i, node) =>
            toggle on, $(node)
        else if $onNodes.length == $nodes.length and not @selectAllActive()
          @$selectAll.addClass('on')
          toggle on, @$selectAll
          $onNodes.each (i, node) =>
            toggle off, $(node)

    onKeydown: (e) ->
      $target = $(e.target)
      code    = e.keyCode or e.which
      fn      = "on#{@keyCodes[code]}Key"
      if @[fn]
        @[fn].call(this, e, $target) and e.preventDefault()
      else if _.include([16, 17, 18, 92], code)
        # shift, control, alt, and command; do nothing
      else
        # focus input and pass to it
        @selector.input.focus()
        $(@selector.input.$input).trigger(e)

    onBlur: (e) ->
      $(e.target).removeClass('active')
      @selector.blur?()

    onFocus: (e) ->
      $(e.target).addClass('active')

    onUpArrowKey: (e, $target) ->
      e.preventDefault()
      @selector.selectPrev()
      if $target.prev().length == 0
        @selector.input.focus()

    onDownArrowKey: (e, $target) ->
      e.preventDefault()
      @selector.selectNext()

    onRightArrowKey: (e, $target) ->
      e.preventDefault()
      @selector.expandSelection()

    onLeftArrowKey: (e, $target) ->
      if @selector.listExpanded()
        @selector.collapse()

    onEnterKey: (e, $target) ->
      e.preventDefault()
      @selectResult($target)

    onSpaceKey: (e, $target) ->
      e.preventDefault()
      @selectResult($target)

    onEscapeKey: (e, $target) ->
      @selector.input.focus()
      @selector.close()

    selectResult: ($result) ->
      if $result.hasClass('expandable') and $result.find('a.toggle').length > 0
        @selector.toggleSelection()
      else
        $result.click()
