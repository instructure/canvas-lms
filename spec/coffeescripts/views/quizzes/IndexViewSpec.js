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

define(
  [
    'Backbone',
    'compiled/models/Quiz',
    'compiled/collections/QuizCollection',
    'compiled/views/quizzes/IndexView',
    'compiled/views/quizzes/QuizItemGroupView',
    'compiled/views/quizzes/NoQuizzesView',
    'jquery',
    'helpers/fakeENV',
    'helpers/jquery.simulate'
  ],
  function(
    Backbone,
    Quiz,
    QuizCollection,
    IndexView,
    QuizItemGroupView,
    NoQuizzesView,
    $,
    fakeENV
  ) {
    let fixtures = null

    const indexView = function(assignments, open, surveys) {
      $('<div id="content"></div>').appendTo(fixtures)

      if (assignments == null) {
        assignments = new QuizCollection([])
      }
      if (open == null) {
        open = new QuizCollection([])
      }
      if (surveys == null) {
        surveys = new QuizCollection([])
      }

      const assignmentView = new QuizItemGroupView({
        collection: assignments,
        title: 'Assignment Quizzes',
        listId: 'assignment-quizzes',
        isSurvey: false
      })

      const openView = new QuizItemGroupView({
        collection: open,
        title: 'Practice Quizzes',
        listId: 'open-quizzes',
        isSurvey: false
      })

      const surveyView = new QuizItemGroupView({
        collection: surveys,
        title: 'Surveys',
        listId: 'surveys-quizzes',
        isSurvey: true
      })

      const noQuizzesView = new NoQuizzesView()

      const permissions = {create: true, manage: true}
      const flags = {question_banks: true}
      const urls = {
        new_quiz_url: '/courses/1/quizzes/new?fresh=1',
        question_banks_url: '/courses/1/question_banks'
      }

      const view = new IndexView({
        assignmentView,
        openView,
        surveyView,
        noQuizzesView,
        permissions,
        flags,
        urls
      })
      view.$el.appendTo(fixtures)
      return view.render()
    }

    QUnit.module('IndexView', {
      setup() {
        fixtures = $('#fixtures')
        fakeENV.setup()
      },
      teardown() {
        fakeENV.teardown()
        fixtures.empty()
      }
    })

    // hasNoQuizzes
    test('#hasNoQuizzes if assignment and open quizzes are empty', function() {
      const assignments = new QuizCollection([])
      const open = new QuizCollection([])

      const view = indexView(assignments, open)
      ok(view.options.hasNoQuizzes)
    })

    test('#hasNoQuizzes to false if has assignement quizzes', function() {
      const assignments = new QuizCollection([{id: 1}])
      const open = new QuizCollection([])

      const view = indexView(assignments, open)
      ok(!view.options.hasNoQuizzes)
    })

    test('#hasNoQuizzes to false if has open quizzes', function() {
      const assignments = new QuizCollection([])
      const open = new QuizCollection([{id: 1}])

      const view = indexView(assignments, open)
      ok(!view.options.hasNoQuizzes)
    })

    // has*
    test('#hasAssignmentQuizzes if has assignment quizzes', function() {
      const assignments = new QuizCollection([{id: 1}])

      const view = indexView(assignments, null, null)
      ok(view.options.hasAssignmentQuizzes)
    })

    test('#hasOpenQuizzes if has open quizzes', function() {
      const open = new QuizCollection([{id: 1}])

      const view = indexView(null, open, null)
      ok(view.options.hasOpenQuizzes)
    })

    test('#hasSurveys if has surveys', function() {
      const surveys = new QuizCollection([{id: 1}])

      const view = indexView(null, null, surveys)
      ok(view.options.hasSurveys)
    })

    // search filter
    test('should render the view', function() {
      const assignments = new QuizCollection([
        {id: 1, title: 'Foo Title'},
        {id: 2, title: 'Bar Title'}
      ])
      const open = new QuizCollection([{id: 3, title: 'Foo Title'}, {id: 4, title: 'Bar Title'}])
      const view = indexView(assignments, open)

      equal(view.$el.find('.collectionViewItems li').length, 4)
    })

    test('should filter by search term', function() {
      const assignments = new QuizCollection([
        {id: 1, title: 'Foo Name'},
        {id: 2, title: 'Bar Title'}
      ])
      const open = new QuizCollection([{id: 3, title: 'Baz Title'}, {id: 4, title: 'Qux Name'}])

      let view = indexView(assignments, open)
      $('#searchTerm').val('foo')
      view.filterResults()
      equal(view.$el.find('.collectionViewItems li').length, 1)

      view = indexView(assignments, open)
      $('#searchTerm').val('name')
      view.filterResults()
      equal(view.$el.find('.collectionViewItems li').length, 2)
    })
  }
)
