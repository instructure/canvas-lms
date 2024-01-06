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

import $ from 'jquery'
import {assignIn, map} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../jst/index.handlebars'
import htmlEscape from '@instructure/html-escape'

// #
// Build a combo box to represent a list of items.
export default class ComboBox {
  // #
  // Takes a list of items to fill the combobox, and the following options:
  //
  //      value: A function that produces the option value for a given item.
  //             Defaults to pulling the value property of the item.
  //
  //      label: A function that produces the option content for a given item.
  //             Defaults to pulling the label property of the item.
  //
  //   selected: The value of the initial selection. If absent, the first item
  //             will be the initial selection.
  //
  // Aside from evalutation by the value and label functions, the provided
  // items are opaque to the combo box. Whenever the selection changes, the
  // 'change' event on this object will be triggered with the item as
  // argument.
  constructor(items, opts = {}) {
    this.items = items

    // override item transforms
    if (opts.value != null) this._value = opts.value
    if (opts.label != null) this._label = opts.label

    // construct dom tree and cache relevant pieces
    this.$el = $(template())
    this.$prev = $('.ui-combobox-prev', this.$el)
    this.$next = $('.ui-combobox-next', this.$el)
    this.$menu = $('select', this.$el)

    // populate and instantiate the selectmenu
    const itemList = map(this.items, this._buildOption)
    // We can't use a spread here because xsslint doesn't like it.
    // xsslint safeString.identifier itemList
    this.$menu.append.apply(this.$menu, itemList) // eslint-disable-line prefer-spread

    // set initial selection
    if (opts.selected != null) {
      this.select(opts.selected)
    }

    // attach event handlers
    assignIn(this, Backbone.Events)
    this.$menu.change(() => this.trigger('change', this.selected()))
    this.$prev.bind('click', this._previous)
    this.$next.bind('click', this._next)
  }

  // #
  // Select a specific item by value.
  select(value) {
    const oldIndex = this._index()
    this.$menu.val(value)

    // setting the value directly doesn't fire the change event, so we'll
    // trigger it ourselves, but only if there was an actual change.
    if (this._index() !== oldIndex) {
      this.$menu.change()
    }

    // return self for chaining
    return this
  }

  // #
  // Retrieve the currently selected item.
  selected() {
    return this.items[this._index()]
  }

  // #
  // @api private
  // The index of the selected item.
  _index() {
    return this.$menu[0].selectedIndex
  }

  // #
  // @api private
  // Select the previous item in the combo.
  _previous = e => {
    e.preventDefault()
    e.stopPropagation()

    // n-1 and -1 are equal modulo n
    const newIndex = (this._index() + this.items.length - 1) % this.items.length
    return this.select(this._value(this.items[newIndex]))
  }

  // #
  // @api private
  // Select the next item in the combo.
  _next = e => {
    e.preventDefault()
    e.stopPropagation()

    const newIndex = (this._index() + 1) % this.items.length
    return this.select(this._value(this.items[newIndex]))
  }

  // #
  // @api private
  // Default item to value conversion.
  _value(item) {
    return item.value
  }

  // #
  // @api private
  // Default item to label conversion.
  _label(item) {
    return item.label
  }

  // #
  // @api private
  // Build an <option> tag for an item.
  _buildOption = item =>
    `<option value='${htmlEscape(this._value(item))}'>${htmlEscape(this._label(item))}</option>`
}
