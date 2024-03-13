/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import 'jquery-migrate'
import InputFilterView from '@canvas/backbone-input-filter-view'
import '@canvas/jquery/jquery.simulate'

let view
let clock = null

QUnit.module('InputFilterView', {
  setup() {
    clock = sinon.useFakeTimers()
  },

  teardown() {
    clock.restore()
    view.remove()
  },
})

function createAndRenderView(options = {}) {
  view = new InputFilterView(options)
  view.render()
  view.$el.appendTo($('#fixtures'))
}

const setValue = term => (view.el.value = term)

const simulateKeyup = function (inputDelay = view.options.onInputDelay) {
  view.$el.simulate('keyup')
  return clock.tick(inputDelay)
}

test('fires input event, sends value', () => {
  createAndRenderView()
  const spy = sinon.spy()
  view.on('input', spy)
  setValue('foo')
  simulateKeyup()
  ok(spy.called)
  ok(spy.calledWith('foo'))
})

test('delays firing the event until input delay has passed', () => {
  createAndRenderView({onInputDelay: 150})
  const onInput = sinon.spy()
  view.on('input', onInput)
  setValue('foo')
  simulateKeyup(100)
  equal(onInput.callCount, 0)
  clock.tick(100)
  equal(onInput.callCount, 1)
})

test('does not fire input event if value has not changed', () => {
  createAndRenderView()
  const spy = sinon.spy()
  view.on('input', spy)
  setValue('foo')
  simulateKeyup()
  simulateKeyup()
  ok(spy.calledOnce)
})

test('updates the model attribute', () => {
  createAndRenderView()
  view.model = new Backbone.Model()
  setValue('foo')
  simulateKeyup()
  equal(view.model.get('filter'), 'foo')
})

test('updates the collection parameter', () => {
  createAndRenderView()
  view.collection = new Backbone.Collection()
  setValue('foo')
  simulateKeyup()
  const actual = view.collection.options.params.filter
  equal(actual, 'foo')
})

test('gets modelAttribute from input name', () => {
  createAndRenderView()
  const input = $('<input name="couch">').appendTo($('#fixtures'))
  view = new InputFilterView({
    el: input[0],
  })
  equal(view.modelAttribute, 'couch')
})

test('sets model attribute to empty string with empty value', () => {
  createAndRenderView()
  view.model = new Backbone.Model()
  setValue('foo')
  simulateKeyup()
  setValue('')
  simulateKeyup()
  equal(view.model.get('filter'), '')
})

test('deletes collection paramater on empty value', () => {
  createAndRenderView()
  view.collection = new Backbone.Collection()
  setValue('foo')
  simulateKeyup()
  equal(view.collection.options.params.filter, 'foo')
  setValue('')
  simulateKeyup()
  strictEqual(view.collection.options.params.filter, undefined)
})

test('does nothing with model/collection when the value is less than the minLength', () => {
  createAndRenderView()
  view.model = new Backbone.Model({filter: 'foo'})
  setValue('ab')
  simulateKeyup()
  equal(view.model.get('filter'), 'foo', 'filter attribute did not change')
})

test('does setParam false when the value is less than the minLength and setParamOnInvalid=true', () => {
  createAndRenderView()
  view.model = new Backbone.Model({filter: 'foo'})
  view.options.setParamOnInvalid = true
  setValue('ab')
  simulateKeyup()
  equal(view.model.get('filter'), false, 'filter attribute is false')
})

test('updates filter with small number', () => {
  createAndRenderView()
  view.model = new Backbone.Model({filter: 'foo'})
  view.options.allowSmallerNumbers = false
  setValue('1')
  simulateKeyup()
  equal(view.model.get('filter'), 'foo', 'filter attribute did not change')
  view.options.allowSmallerNumbers = true
  setValue('2')
  simulateKeyup()
  equal(view.model.get('filter'), '2', 'filter attribute did change')
})
