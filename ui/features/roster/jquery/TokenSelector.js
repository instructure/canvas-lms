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
import {once} from 'lodash'
import TokenSelectorList from './TokenSelectorList'
import RecipientCollection from '../backbone/collections/RecipientCollection'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import 'jquery-scroll-into-view'

export default class TokenSelector {
  static initClass() {
    this.prototype.lastFetch = null
  }

  constructor(input, url, options) {
    this.autoSelectFirst = this.autoSelectFirst.bind(this)
    this.mouseMove = this.mouseMove.bind(this)
    this.mouseDown = this.mouseDown.bind(this)
    this.click = this.click.bind(this)
    this.close = this.close.bind(this)
    this.select = this.select.bind(this)
    this.input = input
    this.url = url
    if (options == null) {
      options = {}
    }
    this.options = options
    this.stack = []
    this.cache = {}
    this.$container = $('<div />').addClass('autocomplete_menu')
    this.$menu = $('<div />')
    this.$container.append($('<div />').append(this.$menu))
    this.$container.css('top', 0).css('left', 0)
    this.mode = 'input'
    $('body').append(this.$container)

    this.reposition = () => {
      const offset = this.input.bottomOffset()
      this.$container.css('top', offset.top)
      return this.$container.css('left', offset.left)
    }
    $(window).resize(this.reposition)
    this.close()
  }

  autoSelectFirst(list) {
    if (list == null) {
      ;({list} = this)
    }
    if (list === this.list && this.selection == null) {
      return this.select(list.first(), true)
    }
  }

  browse(data) {
    if (this.uiLocked) return
    // prevent pending searches
    this.clear()
    this.close()
    this.open()
    this.list = this.listForQuery(this.preparePost(data))
    this.list.appendTo(this.$menu)
    this.autoSelectFirst()
    return true
  }

  mouseMove(e) {
    if (this.uiLocked) return
    let $li = $(e.target).closest('li')
    if (!$li.hasClass('selectable')) {
      $li = null
    }
    return this.select($li)
  }

  mouseDown(_e) {
    // sooper hacky... prevent the menu closing on scrollbar drag
    return setTimeout(() => this.input.focus(), 0)
  }

  click(e) {
    if (this.uiLocked) return
    this.mouseMove(e)
    if (this.selection) {
      if ($(e.target).closest('a.expand').length) {
        if (this.selectionExpanded()) {
          this.collapse()
        } else {
          this.expandSelection()
        }
      } else if (this.selectionToggleable() && $(e.target).closest('a.toggle').length) {
        this.toggleSelection()
      } else if (this.selectionExpanded()) {
        this.collapse()
      } else if (this.selectionExpandable()) {
        this.expandSelection()
      } else {
        this.toggleSelection(true)
        this.clear()
        this.close()
      }
    }
    return this.input.focus()
  }

  captureKeyDown(e) {
    const keyCode =
      (e.originalEvent != null ? e.originalEvent.keyIdentifier : undefined) != null
        ? e.originalEvent != null
          ? e.originalEvent.keyIdentifier
          : undefined
        : e.which

    if (this.uiLocked) {
      return true
    }
    if (this.isShowingNoResults() && [13, 'Enter'].includes(keyCode)) {
      return e.preventDefault()
    }

    switch (keyCode) {
      case 'Backspace':
      case 'U+0008':
      case 8:
        if (this.input.val() === '') {
          if (this.listExpanded()) {
            this.collapse()
          } else if (this.$menu.is(':visible')) {
            this.close()
          } else {
            this.input.removeLastToken()
          }
          return true
        }
        break
      case 'Tab':
      case 'U+0009':
      case 9:
        if (this.selection && (this.selectionToggleable() || !this.selectionExpandable())) {
          this.toggleSelection(true)
        }
        this.clear()
        this.close()
        if (this.selection) {
          return true
        }
        break
      case 'Enter':
      case 13:
        if (this.selectionExpanded()) {
          this.collapse()
          return true
        } else if (this.selectionExpandable() && !this.selectionToggleable()) {
          this.expandSelection()
          return true
        } else if (this.selection) {
          this.toggleSelection(true)
          this.clear()
        }
        this.close()
        return true
      case 'Shift':
      case 16: // noop, but we don't want to set the mode to input
        return false
      case 'Esc':
      case 'U+001B':
      case 27:
        if (this.$menu.is(':visible')) {
          this.close()
          return true
        } else {
          return false
        }
      case 'U+0020':
      case 32: // space
        if (this.selectionToggleable() && this.mode === 'menu') {
          this.toggleSelection()
          return true
        }
        break
      case 'Left':
      case 37:
        if (this.listExpanded() && this.input.caret() === 0) {
          if (this.selectionExpanded() || this.input.val() === '') {
            this.collapse()
          } else {
            this.select(this.list.first())
          }
          return true
        }
        break
      case 'Up':
      case 38:
        this.selectPrev()
        return true
      case 'Right':
      case 39:
        if (this.input.caret() === this.input.val().length && this.expandSelection()) {
          return true
        }
        break
      case 'Down':
      case 40:
        this.selectNext()
        return true
      case 'U+002B':
      case 187:
      case 107: // plus
        if (this.selectionToggleable() && this.mode === 'menu') {
          this.toggleSelection(true)
          return true
        }
        break
      case 'U+002D':
      case 189:
      case 109: // minus
        if (this.selectionToggleable() && this.mode === 'menu') {
          this.toggleSelection(false)
          return true
        }
        break
    }
    this.mode = 'input'
    this.updateSearch()
    return false
  }

  open() {
    this.$container.show()
    return this.reposition()
  }

  close() {
    let list
    this.uiLocked = false
    this.$container.hide()
    if (this.list != null) {
      this.list.remove()
    }
    for (let i = 0; i < this.stack.length; i++) {
      ;[, list] = this.stack[i]
      list.remove()
    }
    this.list = null
    this.stack = []
    this.$menu.css('left', 0)
    this.select(null)
    return this.input.selectorClosed()
  }

  clear() {
    clearTimeout(this.timeout)
    this.input.val('')
    return this.select(null)
  }

  blur() {
    // It seems we can't check focus while it is being changed, so check it later.
    return setTimeout(() => {
      if (
        !this.input.hasFocus() &&
        (!(this.$container.find('.active').length > 0) || this.isShowingNoResults())
      ) {
        return this.close()
      }
    }, 0)
  }

  isShowingNoResults() {
    return this.$menu.find('.no-results').length > 0
  }

  listExpanded() {
    if (this.stack.length) {
      return true
    } else {
      return false
    }
  }

  parent() {
    if (this.listExpanded()) {
      return this.stack[this.stack.length - 1][0]
    } else {
      return null
    }
  }

  selectionExpanded() {
    let left
    return (left = this.selection != null ? this.selection.hasClass('expanded') : undefined) != null
      ? left
      : false
  }

  selectionExpandable() {
    let left
    return (left = this.selection != null ? this.selection.hasClass('expandable') : undefined) !=
      null
      ? left
      : false
  }

  selectionToggleable($node) {
    let left
    if ($node == null) {
      $node = this.selection
    }
    return (
      ((left = $node != null ? $node.hasClass('toggleable') : undefined) != null ? left : false) &&
      !this.selectionExpanded()
    )
  }

  expandSelection() {
    if (!this.selectionExpandable() || !!this.selectionExpanded()) {
      return false
    }
    this.stack.push([this.selection, this.list])
    this.clear()
    this.$menu.css('width', (this.stack.length + 1) * 100 + '%')

    this.uiLocked = true
    const list = this.listForQuery(this.preparePost())
    list.insertAfter(this.list)
    return this.$menu.animate({left: `-=${this.$menu.parent().css('width')}`}, 'fast', () => {
      return this.list.hide(() => {
        this.list = list
        this.autoSelectFirst()
        return (this.uiLocked = false)
      })
    })
  }

  collapse() {
    if (!this.listExpanded()) {
      return false
    }
    const [$selection, list] = Array.from(this.stack.pop())
    this.uiLocked = true
    list.restore()
    return this.$menu.animate({left: `+=${this.$menu.parent().css('width')}`}, 'fast', () => {
      this.list.remove()
      this.list = list
      this.input.val(this.list.query.search)
      this.select($selection)
      return (this.uiLocked = false)
    })
  }

  toggleSelection(state, $node, toggleOnly) {
    if ($node == null) {
      $node = this.selection
    }
    if (toggleOnly == null) {
      toggleOnly = false
    }
    if (state == null && !this.selectionToggleable($node)) {
      return false
    }
    const id = $node.data('id')
    if (state == null) {
      state = !$node.hasClass('on')
    }
    if (state) {
      let left
      if (this.selectionToggleable($node) && !toggleOnly) {
        $node.addClass('on')
      }
      this.input.addToken({
        value: id,
        text: (left = $node.data('text')) != null ? left : $node.text(),
        noClear: true,
        data: $node.data('user_data'),
      })
    } else {
      if (!toggleOnly) {
        $node.removeClass('on')
      }
      this.input.removeToken({value: id})
    }
    if (!toggleOnly) {
      return this.updateSelectAll($node)
    }
  }

  updateSelectAll($node, offset = 0) {
    const selectAllToggled = $node.data('user_data').selectAll
    const list = offset ? this.stack[this.stack.length - offset][1] : this.list
    if (!list.canSelectAll()) {
      return
    }
    list.updateSelectAll(selectAllToggled, (state, $node) => {
      return this.toggleSelection(state, $node, true)
    })

    if (offset < this.stack.length) {
      offset++
      const $parentNode = this.stack[this.stack.length - offset][0]
      if (this.selectionToggleable($parentNode)) {
        if (list.selectAllActive()) {
          $parentNode.addClass('on')
        } else {
          $parentNode.removeClass('on')
        }
        return this.updateSelectAll($parentNode, offset)
      }
    }
  }

  select($node, preserveMode = false) {
    if (
      ($node != null ? $node[0] : undefined) ===
      (this.selection != null ? this.selection[0] : undefined)
    ) {
      return
    }
    this.selection = (() => {
      if ($node != null ? $node.length : undefined) {
        $node.focus()
        $node.scrollIntoView({ignore: {border: true}})
        return $node
      } else {
        return null
      }
    })()
    if (!preserveMode) {
      return (this.mode = $node ? 'menu' : 'input')
    }
  }

  selectNext(preserveMode = false) {
    this.select(
      this.selection
        ? this.selection.next().length
          ? this.selection.next()
          : this.selection.parent('ul').next().length
          ? this.selection.parent('ul').next().find('li').first()
          : null
        : this.list != null
        ? this.list.first()
        : undefined,
      preserveMode
    )
    if (this.selection != null ? this.selection.hasClass('message') : undefined) {
      return this.selectNext(preserveMode)
    }
  }

  selectPrev() {
    this.select(
      this.selection
        ? (this.selection != null ? this.selection.prev().length : undefined)
          ? this.selection.prev()
          : this.selection.parent('ul').prev().length
          ? this.selection.parent('ul').prev().find('li').last()
          : null
        : this.list != null
        ? this.list.last()
        : undefined
    )
    if (this.selection != null ? this.selection.hasClass('message') : undefined) {
      return this.selectPrev()
    }
  }

  updateSearch() {
    // do it in a timeout both so (1) the triggering keystroke can make it
    // into @input before we try and use it, and (2) a rapid sequence of keys
    // only executes the block once at the end.
    clearTimeout(this.timeout)
    this.select(null)
    return (this.timeout = setTimeout(() => {
      if (this.lastFetch && !this.lastFetch.state() === 'resolved') {
        this.nextRequest = true
        return
      }
      const list = this.listForQuery(this.preparePost())
      if (list === this.list) {
        // no change
      } else if (list.query.search === '' && !this.listExpanded()) {
        // changed to where we don't need the menu open anymore
        if (this.$menu.is(':visible')) {
          return this.close()
        }
      } else {
        // activate a new list for the updated search
        if (this.list) {
          list.insertAfter(this.list)
          this.list.remove()
        } else {
          this.open()
          list.appendTo(this.$menu)
        }
        this.list = list
        return this.autoSelectFirst()
      }
    }, 200))
  }

  preparePost(data) {
    const postData = $.extend(
      {},
      this.options.baseData != null ? this.options.baseData : {},
      data != null ? data : {},
      {search: this.input.val().replace(/^\s+|\s+$/g, '')}
    )
    if (postData.exclude == null) {
      postData.exclude = []
    }
    postData.exclude = postData.exclude.concat(this.input.baseExclude)
    if (this.listExpanded()) {
      postData.context = this.parent().data('id')
    } else {
      postData.exclude = postData.exclude.concat(this.input.tokenValues())
    }
    return postData
  }

  collectionForQuery(query) {
    if (this.lastFetch != null) {
      this.lastFetch.abort()
    }
    const cacheKey = JSON.stringify(query)
    if (this.cache[cacheKey] == null) {
      const collection = new RecipientCollection()
      collection.url = this.url
      this.lastFetch = collection.fetch({data: query})
      this.cache[cacheKey] = collection
    }
    return this.cache[cacheKey]
  }

  listForQuery(query) {
    const collection = this.collectionForQuery(query)
    const list = new TokenSelectorList({
      selector: this,
      parent: this.parent(),
      ancestors: Array.from(this.stack).map(ancestor => ancestor[0].data('id')),
      collection,
      query,
    })
    list.render()

    if (!collection.atLeastOnePageFetched) {
      collection.on(
        'fetch',
        once(() => {
          this.autoSelectFirst(list)
          if (this.nextRequest) {
            this.updateSearch()
          }
          return delete this.nextRequest
        })
      )
    }

    return list
  }

  teardown() {
    return this.$container.remove()
  }
}
TokenSelector.initClass()
