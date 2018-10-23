//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import $ from 'jquery'
import TokenSelector from './TokenSelector'
import 'jquery.instructure_misc_plugins'

export default class TokenInput {
  constructor($node, options) {
    this.$node = $node
    this.options = options
    this.$node.data('token_input', this)
    this.$fakeInput = $('<div />')
      .css('font-family', this.$node.css('font-family'))
      .insertAfter(this.$node)
      .addClass('token_input')
      .click(() => this.$input.focus())
    this.nodeName = this.$node.attr('name')
    this.$node
      .removeAttr('name')
      .hide()
      .change(() => {
        this.$tokens.html('')
        return typeof this.change === 'function' ? this.change(this.tokenValues()) : undefined
      })

    this.added = this.options.added
    this.change = this.options.change

    this.$placeholder = $('<span />')
    this.$placeholder.text(this.options.placeholder)
    if (this.options.placeholder) {
      this.$placeholder.appendTo(this.$fakeInput)
    }

    this.$scroller = $('<div />').appendTo(this.$fakeInput)
    this.$tokens = $('<ul />').appendTo(this.$scroller)
    this.$tokens.click(e => {
      let $token
      if (($token = $(e.target).closest('li'))) {
        const $close = $(e.target).closest('a')
        if ($close.length) {
          $token.remove()
          return typeof this.change === 'function' ? this.change(this.tokenValues()) : undefined
        }
      }
    })

    this.$tokens.maxTokenWidth = () =>
      parseInt(this.$tokens.css('width').replace('px', '')) -
      (this.options.tokenWrapBuffer != null ? this.options.tokenWrapBuffer : 150) +
      'px'
    this.$tokens.resizeTokens = tokens =>
      tokens.find('div.ellipsis').css('max-width', this.$tokens.maxTokenWidth())
    $(window).resize(() => this.$tokens.resizeTokens(this.$tokens))

    // key capture input
    this.$input = $('<input name="token_capture" />')
      .attr('title', this.options.title)
      .appendTo(this.$scroller)
      .css('width', '20px')
      .css('font-size', this.$fakeInput.css('font-size'))
      .autoGrowInput({comfortZone: 20})
      .focus(() => {
        this.$placeholder.hide()
        this.active = true
        return this.$fakeInput.addClass('active')
      })
      .blur(() => {
        this.active = false
        return setTimeout(() => {
          if (!this.active) {
            this.$fakeInput.removeClass('active')
            this.$placeholder.showIf(this.val() === '' && !this.$tokens.find('li').length)
            return __guardMethod__(this.selector, 'blur', o => o.blur())
          }
        }, 50)
      })
      .keydown(e => this.inputKeyDown(e))
      .keyup(e => this.inputKeyUp(e))

    if (this.options.selector) {
      const type = this.options.selector.type != null ? this.options.selector.type : TokenSelector
      delete this.options.selector.type
      if ((this.browser = this.options.selector.browser)) {
        delete this.options.selector.browser
        const activateBrowse = () => {
          if (this.selector.browse(this.browser.data)) {
            return this.$fakeInput.addClass('browse')
          }
        }
        $('<a href="#" class="browser">browse</a>')
          .click(activateBrowse)
          .keypress(activateBrowse)
          .appendTo(this.$fakeInput)
        this.$fakeInput.addClass('browsable')
      }
      this.selector = new type(this, this.$node.data('finder_url'), this.options.selector)
    }

    this.baseExclude = []

    this.resize()
  }

  teardown() {
    return this.selector.teardown()
  }

  resize() {
    const width = this.options.fakeInputWidth || this.$node.css('width')
    return this.$fakeInput.css('width', width)
  }

  addToken(data) {
    const val =
      (data != null ? data.value : undefined) != null
        ? data != null
          ? data.value
          : undefined
        : this.val()
    const id = `token_${val}`
    let $token = this.$tokens.find(`#${id}`)
    const newToken = $token.length === 0
    if (newToken) {
      $token = $('<li />')
      const text =
        (data != null ? data.text : undefined) != null
          ? data != null
            ? data.text
            : undefined
          : this.val()
      $token.attr('id', id)
      const $text = $('<div />').addClass('ellipsis')
      $text.attr('title', text)
      $text.text(text)
      $token.append($text)
      const $close = $('<a/>')
      $close.append($('<i class="icon-x" aria-hidden="true"></i>'))
      $token.append($close)
      $token.append(
        $('<input />')
          .attr('type', 'hidden')
          .attr('name', `${this.nodeName}[]`)
          .val(val)
      )
      if (this.options.onNewToken) {
        this.options.onNewToken($token)
      }
      // has to happen before append, so that its unlimited width doesn't make
      // @$tokens grow (which would then keep us from limiting it)
      this.$tokens.resizeTokens($token)
      this.$tokens.append($token)
    }
    if (!(data != null ? data.noClear : undefined)) {
      this.val('')
    }
    this.$placeholder.hide()
    if (data) {
      if (typeof this.added === 'function') {
        this.added(data.data, $token, newToken)
      }
    }
    if (typeof this.change === 'function') {
      this.change(this.tokenValues())
    }
    return this.reposition()
  }

  hasToken(data) {
    return (
      this.$tokens.find(
        `#token_${
          (data != null ? data.value : undefined) != null
            ? data != null
              ? data.value
              : undefined
            : data
        }`
      ).length > 0
    )
  }

  removeToken(data) {
    const id = `token_${
      (data != null ? data.value : undefined) != null
        ? data != null
          ? data.value
          : undefined
        : data
    }`
    this.$tokens.find(`#${id}`).remove()
    if (typeof this.change === 'function') {
      this.change(this.tokenValues())
    }
    return this.reposition()
  }

  removeLastToken(data) {
    this.$tokens
      .find('li')
      .last()
      .remove()
    if (typeof this.change === 'function') {
      this.change(this.tokenValues())
    }
    return this.reposition()
  }

  reposition() {
    if (this.selector != null) {
      this.selector.reposition()
    }
    return this.$scroller.scrollTop(this.$scroller.prop('scrollHeight'))
  }

  inputKeyDown(e) {
    let left
    this.keyUpAction = false
    if (this.selector) {
      if (this.selector != null ? this.selector.captureKeyDown(e) : undefined) {
        e.preventDefault()
        return false
      } else {
        // as soon as we start typing, we are no longer in browse mode
        this.$fakeInput.removeClass('browse')
      }
    } else if ((left = Array.from(this.delimiters).includes(e.which)) != null ? left : []) {
      this.keyUpAction = this.addToken
      e.preventDefault()
      return false
    }
    return true
  }

  tokenPairs() {
    return (() => {
      const result = []
      for (const li of Array.from(this.$tokens.find('li'))) {
        const $li = $(li)
        result.push([$li.find('input').val(), $li.find('div').attr('title')])
      }
      return result
    })()
  }

  tokenValues() {
    return Array.from(this.$tokens.find(`[name='${this.nodeName}[]']`)).map(input => input.value)
  }

  inputKeyUp(e) {
    this.reposition()
    return typeof this.keyUpAction === 'function' ? this.keyUpAction() : undefined
  }

  bottomOffset() {
    const offset = this.$fakeInput.offset()
    offset.top += this.$fakeInput.height() + 2
    return offset
  }

  focus() {
    return this.$input.focus()
  }

  hasFocus() {
    return this.active
  }

  val(val) {
    if (val != null) {
      if (val !== this.$input.val()) {
        this.$input.val(val).change()
        return this.reposition()
      }
    } else {
      return this.$input.val()
    }
  }

  caret() {
    let end, start
    if (this.$input[0].selectionStart != null) {
      start = this.$input[0].selectionStart
      end = this.$input[0].selectionEnd
    } else {
      const val = this.val()
      let range = document.selection.createRange().duplicate()
      range.moveEnd('character', val.length)
      start = range.text === '' ? val.length : val.lastIndexOf(range.text)

      range = document.selection.createRange().duplicate()
      range.moveStart('character', -val.length)
      end = range.text.length
    }
    if (start === end) {
      return start
    } else {
      return -1
    }
  }

  selectorClosed() {
    return this.$fakeInput.removeClass('browse')
  }
}

$.fn.tokenInput = function(options) {
  return this.each(function() {
    return new TokenInput($(this), $.extend(true, {}, options))
  })
}

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName)
  } else {
    return undefined
  }
}
