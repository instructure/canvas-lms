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

import Quiz from '@canvas/quizzes/backbone/models/Quiz'
import QuizCollection from 'ui/features/quizzes_index/backbone/collections/QuizCollection'
import QuizItemGroupView from 'ui/features/quizzes_index/backbone/views/QuizItemGroupView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import '@canvas/jquery/jquery.simulate'

const createView = function (collection) {
  if (collection == null) {
    collection = new QuizCollection([
      {
        id: 1,
        title: 'Foo',
        permissions: {delete: true},
      },
      {
        id: 2,
        title: 'Bar',
        permissions: {delete: true},
      },
    ])
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
  },
})

// eslint-disable-next-line qunit/resolve-async
test('it should be accessible', assert => {
  const view = createView()
  const done = assert.async()
  return assertions.isAccessible(view, done, {a11yReport: true})
})

test('#isEmpty is false if any items arent hidden', () => {
  const view = createView()
  ok(!view.isEmpty())
})

test('#isEmpty is true if collection is empty', () => {
  const collection = new QuizCollection([])
  const view = createView(collection)
  ok(view.isEmpty())
})

test('#isEmpty is true if all items are hidden', () => {
  const collection = new QuizCollection([
    {id: 1, hidden: true},
    {id: 2, hidden: true},
  ])
  const view = createView(collection)
  ok(view.isEmpty())
})

test('should filter models with title that doesnt match term', () => {
  const view = createView()
  const model = new Quiz({title: 'Foo Name'})

  ok(view.filter(model, 'name'))
  ok(!view.filter(model, 'zzz'))
})

test('should not use regexp to filter models', () => {
  const view = createView()
  const model = new Quiz({title: 'Foo Name'})

  ok(!view.filter(model, '.*name'))
  ok(!view.filter(model, 'zzz'))
})

test('should filter models with multiple terms', () => {
  const view = createView()
  const model = new Quiz({title: 'Foo Name bar'})

  ok(view.filter(model, 'name bar'))
  ok(!view.filter(model, 'zzz'))
})

test('should rerender on filter change', () => {
  const view = createView()
  equal(view.$el.find('.collectionViewItems li.quiz').length, 2)

  view.filterResults('foo')
  equal(view.$el.find('.collectionViewItems li.quiz').length, 1)
})

test('should not render no content message if quizzes are available', () => {
  const view = createView()
  equal(view.$el.find('.collectionViewItems li.quiz').length, 2)
  ok(!view.$el.find('.no_content').is(':visible'))
})

test('should render no content message if no quizzes available', () => {
  const collection = new QuizCollection([])
  const view = createView(collection)
  equal(view.$el.find('.collectionViewItems li.quiz').length, 0)
  ok(view.$el.find('.no_content').is(':visible'))
})

test('clicking the header should toggle arrow state', () => {
  const view = createView()

  ok(view.$('.element_toggler i').hasClass('icon-mini-arrow-down'))
  ok(!view.$('.element_toggler i').hasClass('icon-mini-arrow-right'))

  view.$('.element_toggler').simulate('click')

  ok(!view.$('.element_toggler i').hasClass('icon-mini-arrow-down'))
  ok(view.$('.element_toggler i').hasClass('icon-mini-arrow-right'))
})
