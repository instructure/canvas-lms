/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import ComboBox from 'compiled/widget/ComboBox'
import simulateClick from 'helpers/simulateClick'

QUnit.module('ComboBox', {
  teardown() {
    // remove a combobox if one was created
    if (this.combobox != null) {
      this.combobox.$el.remove()
    }
  }
})

function confirmSelected(combobox, item) {
  equal(combobox.$menu.val(), combobox._value(item))
}

test('constructor: dom setup', function() {
  const items = [
    {label: 'label1', value: 'value1'},
    {label: 'label2', value: 'value2'},
    {label: 'label3', value: 'value3'}
  ]
  this.combobox = new ComboBox(items)

  // should have the infrastructure in place
  ok(this.combobox.$el.hasClass('ui-combobox'))
  ok(this.combobox.$prev.hasClass('ui-combobox-prev'))
  ok(this.combobox.$next.hasClass('ui-combobox-next'))
  ok(this.combobox.$menu[0].tagName, 'SELECT')

  // should have the options (both flavors) set up according to items
  const options = $('option', this.combobox.$menu)

  equal(options.length, 3)
  for (let i = 0; i < items.length; i++) {
    const item = items[i]
    equal(options.eq(i).prop('value'), item.value)
    equal(options.eq(i).text(), item.label)
  }

  // should have the first item selected
  confirmSelected(this.combobox, items[0])
})

test('constructor: value', function() {
  const items = [
    {label: 'label1', id: 'id1'},
    {label: 'label2', id: 'id2'},
    {label: 'label3', id: 'id3'}
  ]
  const valueFunc = item => item.id
  this.combobox = new ComboBox(items, {value: valueFunc})

  const options = $('option', this.combobox.$menu)
  for (let i = 0; i < items.length; i++) {
    const item = items[i]
    equal(options.eq(i).prop('value'), valueFunc(item))
  }
})

test('constructor: label', function() {
  const items = [
    {name: 'name1', value: 'value1'},
    {name: 'name2', value: 'value2'},
    {name: 'name3', value: 'value3'}
  ]
  const labelFunc = item => item.name
  this.combobox = new ComboBox(items, {label: labelFunc})

  const options = $('option', this.combobox.$menu)
  for (let i = 0; i < items.length; i++) {
    const item = items[i]
    equal(options.eq(i).text(), labelFunc(item))
  }
})

test('constructor: selected', function() {
  const items = [
    {label: 'label1', value: 'value1'},
    {label: 'label2', value: 'value2'},
    {label: 'label3', value: 'value3'}
  ]
  const selectedItem = items[2]
  this.combobox = new ComboBox(items, {selected: selectedItem.value})

  // should have the specified item selected
  confirmSelected(this.combobox, selectedItem)
})

test('constructor: value and selected', function() {
  const items = [
    {label: 'label1', id: 'id1'},
    {label: 'label2', id: 'id2'},
    {label: 'label3', id: 'id3'}
  ]
  const selectedItem = items[2]
  const valueFunc = item => item.id
  this.combobox = new ComboBox(items, {
    value: valueFunc,
    selected: valueFunc(selectedItem)
  })

  // should have the specified item selected
  confirmSelected(this.combobox, selectedItem)
})

test('select', function() {
  const items = [
    {label: 'label1', value: 'value1'},
    {label: 'label2', value: 'value2'},
    {label: 'label3', value: 'value3'}
  ]
  this.combobox = new ComboBox(items)
  const spy = this.spy()
  this.combobox.on('change', spy)

  // calling select should change selection and trigger callback with new
  // selected item
  this.combobox.select(items[2].value)
  confirmSelected(this.combobox, items[2])
  // for some reason spy.withArgs(items[2]).calledOnce doesn't work
  ok(spy.calledOnce)
  equal(spy.getCall(0).args[0], items[2])

  // calling with the current selection should not trigger callback
  spy.reset()
  this.combobox.select(items[2].value)
  ok(!spy.called)
})

test('prev button', function() {
  const items = [
    {label: 'label1', value: 'value1'},
    {label: 'label2', value: 'value2'},
    {label: 'label3', value: 'value3'}
  ]
  this.combobox = new ComboBox(items, {selected: items[1].value})
  const spy = this.spy()
  this.combobox.on('change', spy)

  // clicking prev button selects previous element
  simulateClick(this.combobox.$prev[0])
  confirmSelected(this.combobox, items[0])
  ok(spy.calledOnce)
  equal(spy.getCall(0).args[0], items[0])

  // clicking from the front wraps around
  spy.reset()
  simulateClick(this.combobox.$prev[0])
  confirmSelected(this.combobox, items[2])
  ok(spy.calledOnce)
  equal(spy.getCall(0).args[0], items[2])
})

test('prev button: one item', function() {
  const items = [{label: 'label1', value: 'value1'}]
  this.combobox = new ComboBox(items)
  const spy = this.spy()
  this.combobox.on('change', spy)

  // clicking prev button does nothing
  simulateClick(this.combobox.$prev[0])
  confirmSelected(this.combobox, items[0])
  ok(!spy.called)
})

test('next button', function() {
  const items = [
    {label: 'label1', value: 'value1'},
    {label: 'label2', value: 'value2'},
    {label: 'label3', value: 'value3'}
  ]
  this.combobox = new ComboBox(items, {selected: items[1].value})
  const spy = this.spy()
  this.combobox.on('change', spy)

  // clicking prev button selects previous element
  simulateClick(this.combobox.$next[0])
  confirmSelected(this.combobox, items[2])
  ok(spy.calledOnce)
  equal(spy.getCall(0).args[0], items[2])

  // clicking from the front wraps around
  spy.reset()
  simulateClick(this.combobox.$next[0])
  confirmSelected(this.combobox, items[0])
  ok(spy.calledOnce)
  equal(spy.getCall(0).args[0], items[0])
})

test('next button: one item', function() {
  const items = [{label: 'label1', value: 'value1'}]
  this.combobox = new ComboBox(items)
  const spy = this.spy()
  this.combobox.on('change', spy)

  // clicking prev button does nothing
  simulateClick(this.combobox.$next[0])
  confirmSelected(this.combobox, items[0])
  ok(!spy.called)
})
