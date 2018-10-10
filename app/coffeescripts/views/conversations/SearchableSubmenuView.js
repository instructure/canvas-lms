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

import htmlEscape from 'str/htmlEscape'
import I18n from 'i18n!conversations'
import $ from 'jquery'
import _ from 'underscore'
import {View} from 'Backbone'

export default class SearchableSubmenuView extends View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.search = this.search.bind(this)
    this.handleDownArrow = this.handleDownArrow.bind(this)
    this.handleUpArrow = this.handleUpArrow.bind(this)
    this.handleRightArrow = this.handleRightArrow.bind(this)
    super(...args)
  }

  initialize() {
    super.initialize(...arguments)
    const content_type = this.$el.children('[data-content-type]').data('content-type')
    this.$field = $('<input />')
      .attr({
        class: 'dropdown-search',
        type: 'search',
        placeholder: content_type,
        'aria-label': I18n.t(
          'Below this search field is a list of %{content_type}. As you type, the list will be filtered to match your query. Conversation messages will be filtered by whichever option you select.',
          {content_type}
        )
      })
      .keyup(_.debounce(this.search, 100))
      .keydown(this.handleDownArrow)
    this.$announce = $('<span class="screenreader-only" aria-live="polite"></span>')
    const label = this.getMenuRoot().text()
    const $labelledField = $('<label>')
      .append(this.$field)
      .append(this.$announce)
    this.$submenu = this.$el
      .children('.dropdown-menu')
      .prepend($labelledField)
      .find('.inner')
      .keydown(this.handleUpArrow)
    this.getMenuRoot().keydown(this.handleRightArrow)
    return (this.$contents = this.$el.find('li'))
  }

  search() {
    const val = this.$field.val().toLowerCase()
    if (!val) {
      this.$contents.show()
      this.$contents.attr('aria-hidden', false)
    } else {
      this.$contents.each(function() {
        const $entry = $(this)
        const $abbr = $entry.find('abbr')
        const text = $abbr.length ? $abbr.attr('title') : $entry.find('span').text()
        const isMatch = text.toLowerCase().indexOf(val) !== -1
        if (isMatch) {
          $entry.show()
          return $entry.attr('aria-hidden', false)
        } else {
          $entry.hide()
          return $entry.attr('aria-hidden', true)
        }
      })
    }

    const shown_count = this.$contents.filter('[aria-hidden=false]').length
    const result_message = I18n.t(
      {one: 'There is 1 result in the list', other: 'There are %{count} results in the list'},
      {count: shown_count}
    )
    return this.$announce.html(htmlEscape(result_message))
  }

  clearSearch() {
    this.$field.val('')
    return this.search()
  }

  getFirstEntry() {
    return this.$submenu.find('li:not(.divider):visible > a').first()
  }

  getMenuRoot() {
    return this.$el.children('[role=menuitem]')
  }

  handleDownArrow(e) {
    if (e.keyCode !== 40) return
    e.preventDefault()
    return this.getFirstEntry().focus()
  }

  handleUpArrow(e) {
    if (e.keyCode !== 38) return
    if (e.target !== this.getFirstEntry()[0]) return
    e.stopPropagation()
    return this.$field.focus()
  }

  handleRightArrow(e) {
    if (e.keyCode !== 39) return
    e.stopPropagation()
    return this.$field.focus()
  }
}
