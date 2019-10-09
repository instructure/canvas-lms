/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import QuizCollection from 'compiled/collections/QuizCollection'
import IndexView from 'compiled/views/quizzes/IndexView'
import QuizItemGroupView from 'compiled/views/quizzes/QuizItemGroupView'
import NoQuizzesView from 'compiled/views/quizzes/NoQuizzesView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import 'helpers/jquery.simulate'

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
  const permissions = {
    create: true,
    manage: true
  }
  const flags = {
    question_banks: true,
    quiz_lti_enabled: false || ENV.flags.quiz_lti_enabled
  }
  const urls = {
    new_quiz_url: '/courses/1/quizzes/new?fresh=1',
    new_assignment_url: '/courses/1/assignments/new',
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
    fakeENV.setup({
      permissions: {
        create: true,
        manage: true
      },
      flags: {
        question_banks: true
      },
      urls: {
        new_quiz_url: '/courses/1/quizzes/new?fresh=1',
        new_assignment_url: '/courses/1/assignments/new',
        question_banks_url: '/courses/1/question_banks'
      }
    })
  },
  teardown() {
    fakeENV.teardown()
    fixtures.empty()
  }
})
test('#hasNoQuizzes if assignment and open quizzes are empty', () => {
  const assignments = new QuizCollection([])
  const open = new QuizCollection([])
  const view = indexView(assignments, open)
  ok(view.options.hasNoQuizzes)
})
test('#hasNoQuizzes to false if has assignment quizzes', () => {
  const assignments = new QuizCollection([{id: 1}])
  const open = new QuizCollection([])
  const view = indexView(assignments, open)
  ok(!view.options.hasNoQuizzes)
})
test('#hasNoQuizzes to false if has open quizzes', () => {
  const assignments = new QuizCollection([])
  const open = new QuizCollection([{id: 1}])
  const view = indexView(assignments, open)
  ok(!view.options.hasNoQuizzes)
})
test('#hasAssignmentQuizzes if has assignment quizzes', () => {
  const assignments = new QuizCollection([{id: 1}])
  const view = indexView(assignments, null, null)
  ok(view.options.hasAssignmentQuizzes)
})
test('#hasOpenQuizzes if has open quizzes', () => {
  const open = new QuizCollection([{id: 1}])
  const view = indexView(null, open, null)
  ok(view.options.hasOpenQuizzes)
})
test('#hasSurveys if has surveys', () => {
  const surveys = new QuizCollection([{id: 1}])
  const view = indexView(null, null, surveys)
  ok(view.options.hasSurveys)
})
test("shows '+ Quiz' button if quiz lti enabled", () => {
  ENV.flags.quiz_lti_enabled = true
  const view = indexView(null, null, null)
  const $button = view.$('.new_quiz_lti')
  equal($button.length, 1)
  ok(/\?quiz_lti$/.test($button.attr('href')))
})
test("does not show '+ Quiz' button when quiz lti disabled", () => {
  ENV.flags.quiz_lti_enabled = false
  const view = indexView(null, null, null)
  equal(view.$('.new_quiz_lti').length, 0)
})
test('should render the view', () => {
  const assignments = new QuizCollection([
    {
      id: 1,
      title: 'Foo Title'
    },
    {
      id: 2,
      title: 'Bar Title'
    }
  ])
  const open = new QuizCollection([
    {
      id: 3,
      title: 'Foo Title'
    },
    {
      id: 4,
      title: 'Bar Title'
    }
  ])
  const view = indexView(assignments, open)
  equal(view.$el.find('.collectionViewItems li').length, 4)
})
test('should filter by search term', () => {
  const assignments = new QuizCollection([
    {
      id: 1,
      title: 'Foo Name'
    },
    {
      id: 2,
      title: 'Bar Title'
    }
  ])
  const open = new QuizCollection([
    {
      id: 3,
      title: 'Baz Title'
    },
    {
      id: 4,
      title: 'Qux Name'
    }
  ])
  let view = indexView(assignments, open)
  $('#searchTerm').val('foo')
  view.filterResults()
  equal(view.$el.find('.collectionViewItems li').length, 1)
  view = indexView(assignments, open)
  $('#searchTerm').val('name')
  view.filterResults()
  equal(view.$el.find('.collectionViewItems li').length, 2)
})
