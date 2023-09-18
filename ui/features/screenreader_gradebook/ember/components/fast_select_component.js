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

// converted to coffeescript from:
// https://gist.github.com/kselden/7758990

import {Component, get, set} from 'ember'

const doc = document

const FastSelectComponent = Component.extend({
  initialized: false,
  items: null,
  valuePath: 'value',
  labelPath: 'label',
  labelDefault: null,
  valueDefault: '',
  value: null,
  selected: null,
  ariaDescribedBy: null,

  tagName: 'select',

  didInsertElement() {
    const self = this
    if (this.get('ariaDescribedBy')) {
      this.$().attr('aria-describedby', this.get('ariaDescribedBy'))
    }
    return this.$().on('change', function () {
      return set(self, 'value', this.value)
    })
  },

  valueDidChange: function () {
    let selected = null
    if (this.value && this.items) {
      selected = this.items.findBy(this.valuePath, this.value)
    }
    set(this, 'selected', selected || null)
  }.observes('value'),

  initialize: function () {
    const value = this.value || this.valueDefault
    let selected
    if (value && this.items) {
      selected = this.items.findBy(this.valuePath, value)
    }
    set(this, 'selected', selected || null)
  }.on('init'),

  itemsWillChange: function () {
    const {items} = this
    if (items) {
      items.removeArrayObserver(this)
      this.arrayWillChange(items, 0, get(items, 'length'), 0)
    }
  }
    .observesBefore('items')
    .on('willDestroyElement'),

  itemsDidChange: function () {
    const {items} = this
    if (items) {
      items.addArrayObserver(this)
      this.arrayDidChange(items, 0, 0, get(items, 'length'))
    }
  }
    .observes('items')
    .on('didInsertElement'),

  arrayWillChange(items, start, removeCount, _addCount) {
    const select = get(this, 'element')
    const options = select.childNodes
    let i = start + removeCount - 1
    if (get(this, 'hasDefaultOption')) {
      start += 1
      i += 1
    }
    return (() => {
      const result = []
      while (i >= start) {
        select.removeChild(options[i])
        result.push(i--)
      }
      return result
    })()
  },

  updateSelection: function () {
    const selected = get(this, 'selected')
    if (!selected) {
      return
    }
    const currentValue = get(selected, this.valuePath)
    const select = this.$(`[value=${currentValue}]`)
    __guard__(select != null ? select[0] : undefined, x => (x.selected = true))
    if (currentValue && currentValue !== this.value) {
      set(this, 'value', currentValue)
    }
  }.observes('selected'),

  updateOptions: function () {
    this.arrayWillChange(this.items, 0, get(this.items, 'length'), 0)
    this.arrayDidChange(this.items, 0, 0, get(this.items, 'length'))
  }.observes('labelPath'),

  arrayDidChange(items, start, _removeCount, addCount) {
    let value
    const select = get(this, 'element')
    const hasDefault = get(this, 'hasDefaultOption')
    if (hasDefault) {
      start += 1
    }
    let i = start
    const l = start + addCount

    while (i < l) {
      const ind = hasDefault ? i - 1 : i
      const item = items.objectAt(ind)
      value = get(item, this.valuePath)
      const label = get(item, this.labelPath)
      const option = doc.createElement('option')
      option.textContent = label
      option.value = value
      if ((this.value || this.valueDefault) === value) {
        option.selected = true
        set(this, 'selected', item)
      }
      select.appendChild(option)
      i++
    }

    set(this, 'value', select.value)
  },

  insertDefaultOption: function () {
    if (!this.labelDefault || !!this.hasDefaultOption) {
      return
    }
    const select = get(this, 'element')
    const option = doc.createElement('option')
    option.textContent = this.labelDefault
    option.value = this.valueDefault
    select.appendChild(option)

    set(this, 'hasDefaultOption', true)
  }
    .observes('items')
    .on('didInsertElement'),
})

export default FastSelectComponent

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
