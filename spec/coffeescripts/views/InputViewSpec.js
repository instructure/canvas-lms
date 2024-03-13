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
import InputView from '@canvas/backbone-input-view'

let view = null

QUnit.module('InputView', {
  setup() {
    view = new InputView()
    view.render()
    view.$el.appendTo($('#fixtures'))
  },
  teardown() {
    view.remove()
  },
})
const setValue = term => (view.el.value = term)

test('updates the model attribute', () => {
  view.model = new Backbone.Model()
  setValue('foo')
  view.updateModel()
  equal(view.model.get('unnamed'), 'foo')
})

test('updates the collection parameter', () => {
  view.collection = new Backbone.Collection()
  setValue('foo')
  view.updateModel()
  const actual = view.collection.options.params.unnamed
  equal(actual, 'foo')
})

test('gets modelAttribute from input name', () => {
  const input = $('<input name="couch">').appendTo($('#fixtures'))
  view = new InputView({el: input[0]})
  equal(view.modelAttribute, 'couch')
})

test('sets model attribute to empty string with empty value', () => {
  view.model = new Backbone.Model()
  setValue('foo')
  view.updateModel()
  setValue('')
  view.updateModel()
  equal(view.model.get('unnamed'), '')
})

test('deletes collection paramater on empty value', () => {
  view.collection = new Backbone.Collection()
  setValue('foo')
  view.updateModel()
  equal(view.collection.options.params.unnamed, 'foo')
  setValue('')
  view.updateModel()
  strictEqual(view.collection.options.params.unnamed, undefined)
})
