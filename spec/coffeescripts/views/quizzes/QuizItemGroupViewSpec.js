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

import Backbone from 'Backbone'
import Quiz from 'compiled/models/Quiz'
import QuizCollection from 'compiled/collections/QuizCollection'
import QuizItemGroupView from 'compiled/views/quizzes/QuizItemGroupView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

const fixtures = $('#fixtures')

const createView = function(collection) {
  if (collection == null) {
    collection = new QuizCollection([{id: 1, title: 'Foo'}, {id: 2, title: 'Bar'}])
  }
  const view = new QuizItemGroupView({collection, listId: 'assignment-quizzes'})
  view.$el.appendTo($('#fixtures'))
  return view.render()
}

QUnit.module('QuizItemGroupView', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('it should be accessible', function(assert) {
  const view = new createView()
  const done = assert.async()
  return assertions.isAccessible(view, done, {a11yReport: true})
})

test('#isEmpty is false if any items arent hidden', function() {
  const view = new createView()
  ok(!view.isEmpty())
})

test('#isEmpty is true if collection is empty', function() {
  const collection = new QuizCollection([])
  const view = new createView(collection)
  ok(view.isEmpty())
})

test('#isEmpty is true if all items are hidden', function() {
  const collection = new QuizCollection([{id: 1, hidden: true}, {id: 2, hidden: true}])
  const view = new createView(collection)
  ok(view.isEmpty())
})

test('should filter models with title that doesnt match term', function() {
  const collection = new QuizCollection([{id: 1}, {id: 2}])
  const view = createView(collection)
  const model = new Quiz({title: 'Foo Name'})

  ok(view.filter(model, 'name'))
  ok(!view.filter(model, 'zzz'))
})

test('should not use regexp to filter models', function() {
  const collection = new QuizCollection([{id: 1}, {id: 2}])
  const view = createView(collection)
  const model = new Quiz({title: 'Foo Name'})

  ok(!view.filter(model, '.*name'))
  ok(!view.filter(model, 'zzz'))
})

test('should filter models with multiple terms', function() {
  const collection = new QuizCollection([{id: 1}, {id: 2}])
  const view = createView(collection)
  const model = new Quiz({title: 'Foo Name bar'})

  ok(view.filter(model, 'name bar'))
  ok(!view.filter(model, 'zzz'))
})

test('should rerender on filter change', function() {
  const collection = new QuizCollection([{id: 1, title: 'hey'}, {id: 2, title: 'foo'}])
  const view = createView(collection)
  equal(view.$el.find('.collectionViewItems li').length, 2)

  view.filterResults('hey')
  equal(view.$el.find('.collectionViewItems li').length, 1)
})

test('should not render no content message if quizzes are available', function() {
  const collection = new QuizCollection([{id: 1}, {id: 2}])
  const view = createView(collection)
  equal(view.$el.find('.collectionViewItems li').length, 2)
  ok(!view.$el.find('.no_content').is(':visible'))
})

test('should render no content message if no quizzes available', function() {
  const collection = new QuizCollection([])
  const view = createView(collection)
  equal(view.$el.find('.collectionViewItems li').length, 0)
  ok(view.$el.find('.no_content').is(':visible'))
})

test('clicking the header should toggle arrow state', function() {
  const collection = new QuizCollection([{id: 1}, {id: 2}])
  const view = createView(collection)

  ok(view.$('.element_toggler i').hasClass('icon-mini-arrow-down'))
  ok(!view.$('.element_toggler i').hasClass('icon-mini-arrow-right'))

  view.$('.element_toggler').simulate('click')

  ok(!view.$('.element_toggler i').hasClass('icon-mini-arrow-down'))
  ok(view.$('.element_toggler i').hasClass('icon-mini-arrow-right'))
})
