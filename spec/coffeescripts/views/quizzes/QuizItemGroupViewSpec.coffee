#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'compiled/models/Quiz'
  'compiled/collections/QuizCollection'
  'compiled/views/quizzes/QuizItemGroupView'
  'jquery'
  'helpers/fakeENV'
  'helpers/assertions'
  'helpers/jquery.simulate'
], (Backbone, Quiz, QuizCollection, QuizItemGroupView, $, fakeENV, assertions) ->

  fixtures = $('#fixtures')

  createView = (collection) ->
    collection ?= new QuizCollection([{id: 1, title: 'Foo'}, {id: 2, title: 'Bar'}])
    view = new QuizItemGroupView(collection: collection, listId: "assignment-quizzes")
    view.$el.appendTo $('#fixtures')
    view.render()

  QUnit.module 'QuizItemGroupView',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  test 'it should be accessible', (assert) ->
    view = new createView()
    done = assert.async()
    assertions.isAccessible view, done, {'a11yReport': true}

  test '#isEmpty is false if any items arent hidden', ->
    view = new createView()
    ok !view.isEmpty()

  test '#isEmpty is true if collection is empty', ->
    collection = new QuizCollection([])
    view = new createView(collection)
    ok view.isEmpty()

  test '#isEmpty is true if all items are hidden', ->
    collection = new QuizCollection([{id: 1, hidden: true}, {id: 2, hidden: true}])
    view = new createView(collection)
    ok view.isEmpty()


  test 'should filter models with title that doesnt match term', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    model = new Quiz(title: "Foo Name")

    ok  view.filter(model, "name")
    ok !view.filter(model, "zzz")

  test 'should not use regexp to filter models', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    model = new Quiz(title: "Foo Name")

    ok !view.filter(model, ".*name")
    ok !view.filter(model, "zzz")

  test 'should filter models with multiple terms', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    model = new Quiz(title: "Foo Name bar")

    ok  view.filter(model, "name bar")
    ok !view.filter(model, "zzz")


  test 'should rerender on filter change', ->
    collection = new QuizCollection([{id: 1, title: 'hey'}, {id: 2, title: 'foo'}])
    view = createView(collection)
    equal view.$el.find('.collectionViewItems li').length, 2

    view.filterResults('hey')
    equal view.$el.find('.collectionViewItems li').length, 1

  test 'should not render no content message if quizzes are available', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    equal view.$el.find('.collectionViewItems li').length, 2
    ok !view.$el.find('.no_content').is(':visible')

  test 'should render no content message if no quizzes available', ->
    collection = new QuizCollection([])
    view = createView(collection)
    equal view.$el.find('.collectionViewItems li').length, 0
    ok view.$el.find('.no_content').is(':visible')


  test 'clicking the header should toggle arrow state', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)

    ok  view.$('.element_toggler i').hasClass('icon-mini-arrow-down')
    ok !view.$('.element_toggler i').hasClass('icon-mini-arrow-right')

    view.$('.element_toggler').simulate 'click'

    ok !view.$('.element_toggler i').hasClass('icon-mini-arrow-down')
    ok  view.$('.element_toggler i').hasClass('icon-mini-arrow-right')

