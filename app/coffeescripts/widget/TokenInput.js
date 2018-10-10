#
# Copyright (C) 2012 - present Instructure, Inc.
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
  '../widget/TokenSelector'
  'jquery.instructure_misc_plugins'
], ($, TokenSelector) ->

  class TokenInput
    constructor: (@$node, @options) ->
      @$node.data('token_input', this)
      @$fakeInput = $('<div />')
        .css('font-family', @$node.css('font-family'))
        .insertAfter(@$node)
        .addClass('token_input')
        .click => @$input.focus()
      @nodeName = @$node.attr('name')
      @$node.removeAttr('name').hide().change =>
        @$tokens.html('')
        @change?(@tokenValues())

      @added = @options.added
      @change = @options.change

      @$placeholder = $('<span />')
      @$placeholder.text(@options.placeholder)
      @$placeholder.appendTo(@$fakeInput) if @options.placeholder

      @$scroller = $('<div />')
        .appendTo(@$fakeInput)
      @$tokens = $('<ul />')
        .appendTo(@$scroller)
      @$tokens.click (e) =>
        if $token = $(e.target).closest('li')
          $close = $(e.target).closest('a')
          if $close.length
            $token.remove()
            @change?(@tokenValues())

      @$tokens.maxTokenWidth = =>
        (parseInt(@$tokens.css('width').replace('px', '')) - (@options.tokenWrapBuffer ? 150)) + 'px'
      @$tokens.resizeTokens = (tokens) =>
        tokens.find('div.ellipsis').css('max-width', @$tokens.maxTokenWidth())
      $(window).resize =>
        @$tokens.resizeTokens(@$tokens)

      # key capture input
      @$input = $('<input name="token_capture" />')
        .attr('title', @options.title)
        .appendTo(@$scroller)
        .css('width', '20px')
        .css('font-size', @$fakeInput.css('font-size'))
        .autoGrowInput({comfortZone: 20})
        .focus =>
          @$placeholder.hide()
          @active = true
          @$fakeInput.addClass('active')
        .blur =>
          @active = false
          setTimeout =>
            if not @active
              @$fakeInput.removeClass('active')
              @$placeholder.showIf @val() is '' and not @$tokens.find('li').length
              @selector?.blur?()
          , 50
        .keydown (e) =>
          @inputKeyDown(e)
        .keyup (e) =>
          @inputKeyUp(e)

      if @options.selector
        type = @options.selector.type ? TokenSelector
        delete @options.selector.type
        if @browser = @options.selector.browser
          delete @options.selector.browser
          $('<a class="browser">browse</a>')
            .click =>
              if @selector.browse(@browser.data)
                @$fakeInput.addClass('browse')
            .prependTo(@$fakeInput)
          @$fakeInput.addClass('browsable')
        @selector = new type(this, @$node.data('finder_url'), @options.selector)

      @baseExclude = []

      @resize()

    teardown: ->
      @selector.teardown()

    resize: () ->
      width = @options.fakeInputWidth or @$node.css 'width'
      @$fakeInput.css('width', width)

    addToken: (data) ->
      val = data?.value ? @val()
      id = 'token_' + val
      $token = @$tokens.find('#' + id)
      newToken = ($token.length is 0)
      if newToken
        $token = $('<li />')
        text = data?.text ? @val()
        $token.attr('id', id)
        $text = $('<div />').addClass('ellipsis')
        $text.attr('title', text)
        $text.text(text)
        $token.append($text)
        $close = $('<a/>')
        $close.append($('<i class="icon-x" aria-hidden="true"></i>'))
        $token.append($close)
        $token.append($('<input />')
          .attr('type', 'hidden')
          .attr('name', @nodeName + '[]')
          .val(val)
        )
        @options.onNewToken($token) if @options.onNewToken
        # has to happen before append, so that its unlimited width doesn't make
        # @$tokens grow (which would then keep us from limiting it)
        @$tokens.resizeTokens($token)
        @$tokens.append($token)
      @val('') unless data?.noClear
      @$placeholder.hide()
      @added?(data.data, $token, newToken) if data
      @change?(@tokenValues())
      @reposition()

    hasToken: (data) ->
      @$tokens.find('#token_' + (data?.value ? data)).length > 0

    removeToken: (data) ->
      id = 'token_' + (data?.value ? data)
      @$tokens.find('#' + id).remove()
      @change?(@tokenValues())
      @reposition()

    removeLastToken: (data) ->
      @$tokens.find('li').last().remove()
      @change?(@tokenValues())
      @reposition()

    reposition: ->
      @selector?.reposition()
      @$scroller.scrollTop @$scroller.prop("scrollHeight")

    inputKeyDown: (e) ->
      @keyUpAction = false
      if @selector
        if @selector?.captureKeyDown(e)
          e.preventDefault()
          return false
        else # as soon as we start typing, we are no longer in browse mode
          @$fakeInput.removeClass('browse')
      else if e.which in @delimiters ? []
        @keyUpAction = @addToken
        e.preventDefault()
        return false
      true

    tokenPairs: ->
      for li in @$tokens.find('li')
        $li = $(li)
        [$li.find('input').val(), $li.find('div').attr('title')]

    tokenValues: ->
      input.value for input in @$tokens.find("[name='#{@nodeName}[]']")

    inputKeyUp: (e) ->
      @reposition()
      @keyUpAction?()

    bottomOffset: ->
      offset = @$fakeInput.offset()
      offset.top += @$fakeInput.height() + 2
      offset

    focus: ->
      @$input.focus()

    hasFocus: ->
      @active

    val: (val) ->
      if val?
        if val isnt @$input.val()
          @$input.val(val).change()
          @reposition()
      else
        @$input.val()

    caret: ->
      if @$input[0].selectionStart?
        start = @$input[0].selectionStart
        end = @$input[0].selectionEnd
      else
        val = @val()
        range = document.selection.createRange().duplicate()
        range.moveEnd "character", val.length
        start = if range.text == "" then val.length else val.lastIndexOf(range.text)

        range = document.selection.createRange().duplicate()
        range.moveStart "character", -val.length
        end = range.text.length
      if start == end
        start
      else
        -1

     selectorClosed: ->
       @$fakeInput.removeClass('browse')

  $.fn.tokenInput = (options) ->
    @each ->
      new TokenInput $(this), $.extend(true, {}, options)

  TokenInput
