//
// Copyright (C) 2013 - present Instructure, Inc.
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
import _ from 'underscore'
import PaginatedView from '../views/PaginatedView'
import 'jquery.disableWhileLoading'

export default class TokenSelectorList extends PaginatedView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.render = this.render.bind(this)
    this.addOne = this.addOne.bind(this)
    this.showPaginationLoader = this.showPaginationLoader.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.tagName = 'div'
    this.prototype.className = 'list'

    this.prototype.events = {
      'blur li': 'onBlur',
      'focus li': 'onFocus',
      'keydown li': 'onKeydown'
    }

    this.prototype.keyCodes = {
      13: 'Enter',
      16: 'Shift',
      17: 'Control',
      18: 'Alt',
      27: 'Escape',
      32: 'Space',
      37: 'LeftArrow',
      38: 'UpArrow',
      39: 'RightArrow',
      40: 'DownArrow',
      91: 'Command'
    }
  }

  paginationLoaderTemplate() {
    return `\
<div class="pagination-loader" style="height: 60px;">&nbsp;</div>\
`
  }

  initialize(options) {
    this.paginationScrollContainer = $('<ul />', {role: 'menu'})
    super.initialize(...arguments)
    this.selector = this.options.selector
    this.parent = this.options.parent
    this.ancestors = this.options.ancestors
    this.query = this.options.query

    this.$heading = $('<ul />', {class: 'heading'}).appendTo(this.$el)
    this.$body = this.paginationScrollContainer.appendTo(this.$el)

    this.$el
      .find('ul')
      .on('mousemove', this.selector.mouseMove)
      .on('mousedown', this.selector.mouseDown)
      .on('click', this.selector.click)

    this.collection.on('beforeFetch', this.showPaginationLoader, this)
    return this.collection.on('fetch', this.render)
  }

  render() {
    const activeIndex = this.paginationScrollContainer.children('.active').index()
    this.clear()
    this.$selectAll = null

    if (this.parent) {
      const $li = this.parent.clone()
      $li.addClass('expanded').removeClass('active first last')
      this.$heading.append($li).show()
    } else {
      this.$heading.hide()
    }

    if (!this.query.search) {
      if (this.collection.length > 0) {
        const filterText =
          typeof this.selector.options.includeFilterOption === 'function'
            ? this.selector.options.includeFilterOption(this.query)
            : undefined
        if (filterText) {
          this.addFilterOption(filterText)
        }
      }
      if (this.collection.length > 1) {
        const everyoneText =
          typeof this.selector.options.includeEveryoneOption === 'function'
            ? this.selector.options.includeEveryoneOption(this.query, this.parent)
            : undefined
        const selectAllText =
          typeof this.selector.options.includeSelectAllOption === 'function'
            ? this.selector.options.includeSelectAllOption(this.query, this.parent)
            : undefined
        if (everyoneText) {
          this.addEveryoneOption(everyoneText)
        }
        if (selectAllText) {
          this.addSelectAllOption(selectAllText)
        }
      }
    }
    this.collection.each(this.addOne)
    if (this.selectAllActive() || __guardMethod__(this.parent, 'hasClass', o => o.hasClass('on'))) {
      this.$body.find('li.toggleable').addClass('on')
    }
    this.$el.toggleClass(
      'with-toggles',
      this.selector.options.showToggles && this.$body.find('li.toggleable').length > 0
    )
    this.selector.select($(this.paginationScrollContainer.children()[activeIndex]))

    if (this.collection.fetchingPage || this.collection.fetchingNextPage) {
      this.showPaginationLoader()
    } else {
      this.hidePaginationLoader()
    }

    if (this.collection.atLeastOnePageFetched && !this.$body.find('li').length) {
      const $message = $('<li class="message first last no-results"></li>')
      $message.text(
        (this.selector.options.messages != null
          ? this.selector.options.messages.noResults
          : undefined) != null
          ? this.selector.options.messages != null
            ? this.selector.options.messages.noResults
            : undefined
          : ''
      )
      this.$body.append($message)
    }

    return super.render(...arguments)
  }

  addEveryoneOption(everyoneText) {
    const parentData = this.parent.data('user_data')
    const row = {
      id: `${this.query.context}_all`,
      name: everyoneText,
      user_count: parentData.user_count,
      type: 'context',
      avatar_url: parentData.avatar_url
    }
    if (this.selector.options.includeSelectAllOption) {
      $.extend(row, {
        permissions: parentData.permissions,
        selectAll: parentData.permissions.send_messages_all
      })
    }
    return this.addOneRaw(row)
  }

  addSelectAllOption(selectAllText) {
    const parentData = this.parent.data('user_data')
    return this.addOneRaw({
      id: this.query.context,
      name: selectAllText,
      user_count: parentData.user_count,
      type: 'context',
      avatar_url: parentData.avatar_url,
      permissions: parentData.permissions,
      selectAll: true,
      noExpand: true
    }) // just a magic select-all checkbox, you can't drill into it
  }

  addFilterOption(filterText) {
    return this.addOneRaw({
      id: this.query.context,
      name: this.parent.data('text'),
      type: 'context',
      avatar_url: this.parent.data('user_data').avatar_url,
      subText: filterText,
      noExpand: true
    })
  }

  addOne(recipient) {
    return this.addOneRaw(recipient.attributes)
  }

  addOneRaw(row) {
    const $li = $('<li />', {class: 'selectable', tabindex: '-1'})
    if (!this.$body.find('li:first')) {
      $li.addClass('first')
    }
    this.$body.find('li:last').removeClass('last')
    $li.addClass('last')

    this.populateRow($li, row, {
      level: this.ancestors.length,
      parent: this.parent,
      ancestors: this.ancestors
    })
    if (row.selectAll) {
      this.$selectAll = $li
    }
    if ($li.hasClass('toggleable') && this.selector.input.hasToken($li.data('id'))) {
      $li.addClass('on')
    }
    return this.$body.append($li)
  }

  populateRow($node, data, options) {
    if (options == null) {
      options = {}
    }
    if (this.selector.options.populator) {
      options = $.extend({noExpand: this.selector.options.noExpand}, options)
      return this.selector.options.populator(this.selector, $node, data, options)
    } else {
      $node.data('id', data.text)
      return $node.text(data.text)
    }
  }

  first() {
    return this.$el.find('li:first')
  }

  last() {
    return this.$el.find('li:last')
  }

  appendTo($node) {
    return $node.append(this.$el)
  }

  insertAfter(otherList) {
    return this.$el.insertAfter(otherList.$el)
  }

  remove() {
    return this.$el.remove()
  }

  hide(callback) {
    return this.$el.animate({height: '1px'}, 'fast', callback)
  }

  restore() {
    return this.$el.css('height', 'auto')
  }

  clear() {
    this.$body.empty()
    return this.$heading.empty()
  }

  showPaginationLoader() {
    const rv = super.showPaginationLoader(...arguments)
    this.$paginationLoader.disableWhileLoading(this.collection.deferred)
    return rv
  }

  placePaginationLoader() {
    return this.$paginationLoader != null
      ? this.$paginationLoader.insertAfter(this.$body)
      : undefined
  }

  canSelectAll() {
    return this.$selectAll != null
  }

  selectAllActive() {
    return this.$selectAll != null ? this.$selectAll.hasClass('on') : undefined
  }

  updateSelectAll(selectAllToggled, toggle) {
    if (!this.$selectAll) {
      return
    }
    const $nodes = this.$body.find('li.toggleable').not(this.$selectAll)
    if (selectAllToggled) {
      if (this.selectAllActive()) {
        return $nodes.addClass('on').each((i, node) => {
          return toggle(false, $(node))
        })
      } else {
        return $nodes.removeClass('on').each((i, node) => {
          return toggle(false, $(node))
        })
      }
    } else {
      const $onNodes = $nodes.filter('.on')
      if ($onNodes.length < $nodes.length && this.selectAllActive()) {
        this.$selectAll.removeClass('on')
        toggle(false, this.$selectAll)
        return $onNodes.each((i, node) => {
          return toggle(true, $(node))
        })
      } else if ($onNodes.length === $nodes.length && !this.selectAllActive()) {
        this.$selectAll.addClass('on')
        toggle(true, this.$selectAll)
        return $onNodes.each((i, node) => {
          return toggle(false, $(node))
        })
      }
    }
  }

  onKeydown(e) {
    const $target = $(e.target)
    const code = e.keyCode || e.which
    const fn = `on${this.keyCodes[code]}Key`
    if (this[fn]) {
      return this[fn].call(this, e, $target) && e.preventDefault()
    } else if (_.include([16, 17, 18, 92], code)) {
      // shift, control, alt, and command; do nothing
    } else {
      // focus input and pass to it
      this.selector.input.focus()
      return $(this.selector.input.$input).trigger(e)
    }
  }

  onBlur(e) {
    $(e.target).removeClass('active')
    return typeof this.selector.blur === 'function' ? this.selector.blur() : undefined
  }

  onFocus(e) {
    return $(e.target).addClass('active')
  }

  onUpArrowKey(e, $target) {
    e.preventDefault()
    this.selector.selectPrev()
    if ($target.prev().length === 0) {
      return this.selector.input.focus()
    }
  }

  onDownArrowKey(e, $target) {
    e.preventDefault()
    return this.selector.selectNext()
  }

  onRightArrowKey(e, $target) {
    e.preventDefault()
    return this.selector.expandSelection()
  }

  onLeftArrowKey(e, $target) {
    if (this.selector.listExpanded()) {
      return this.selector.collapse()
    }
  }

  onEnterKey(e, $target) {
    e.preventDefault()
    return this.selectResult($target)
  }

  onSpaceKey(e, $target) {
    e.preventDefault()
    return this.selectResult($target)
  }

  onEscapeKey(e, $target) {
    this.selector.input.focus()
    return this.selector.close()
  }

  selectResult($result) {
    if ($result.hasClass('expandable') && $result.find('a.toggle').length > 0) {
      return this.selector.toggleSelection()
    } else {
      return $result.click()
    }
  }
}
TokenSelectorList.initClass()

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName)
  } else {
    return undefined
  }
}
