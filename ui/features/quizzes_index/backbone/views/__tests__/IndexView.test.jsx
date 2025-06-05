/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import QuizCollection from '../../collections/QuizCollection'
import IndexView from '../IndexView'
import QuizItemGroupView from '../QuizItemGroupView'
import NoQuizzesView from '../NoQuizzesView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import ReactDOM from 'react-dom'

jest.useFakeTimers()

describe('IndexView', () => {
  let fixtures
  let view

  const createIndexView = (assignments, open, surveys) => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    $('<div id="content"></div>').appendTo(fixtures)
    assignments = assignments || new QuizCollection([])
    open = open || new QuizCollection([])
    surveys = surveys || new QuizCollection([])

    const assignmentView = new QuizItemGroupView({
      collection: assignments,
      title: 'Assignment Quizzes',
      listId: 'assignment-quizzes',
      isSurvey: false,
    })

    const openView = new QuizItemGroupView({
      collection: open,
      title: 'Practice Quizzes',
      listId: 'open-quizzes',
      isSurvey: false,
    })

    const surveyView = new QuizItemGroupView({
      collection: surveys,
      title: 'Surveys',
      listId: 'surveys-quizzes',
      isSurvey: true,
    })

    const noQuizzesView = new NoQuizzesView()
    const permissions = {create: true, manage: true}
    const flags = {
      question_banks: true,
      quiz_lti_enabled: ENV.flags?.quiz_lti_enabled || false,
    }
    const urls = {
      new_quiz_url: '/courses/1/quizzes/new?fresh=1',
      new_assignment_url: '/courses/1/assignments/new',
      question_banks_url: '/courses/1/question_banks',
    }

    view = new IndexView({
      assignmentView,
      openView,
      surveyView,
      noQuizzesView,
      permissions,
      flags,
      urls,
    })
    view.$el.appendTo(fixtures)
    return view.render()
  }

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    fakeENV.setup({
      permissions: {
        create: true,
        manage: true,
      },
      flags: {
        question_banks: true,
        quiz_lti_enabled: false,
      },
      urls: {
        new_quiz_url: '/courses/1/quizzes/new?fresh=1',
        new_assignment_url: '/courses/1/assignments/new',
        question_banks_url: '/courses/1/question_banks',
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.removeChild(fixtures)
    jest.resetAllMocks()
  })

  it('has no quizzes if assignment and open quizzes are empty', () => {
    const assignments = new QuizCollection([])
    const open = new QuizCollection([])
    view = createIndexView(assignments, open)
    expect(view.options.hasNoQuizzes).toBeTruthy()
  })

  it('sets hasNoQuizzes to false if has assignment quizzes', () => {
    const assignments = new QuizCollection([{id: 1, permissions: {delete: true}}])
    const open = new QuizCollection([])
    view = createIndexView(assignments, open)
    expect(view.options.hasNoQuizzes).toBeFalsy()
  })

  it('sets hasNoQuizzes to false if has open quizzes', () => {
    const assignments = new QuizCollection([])
    const open = new QuizCollection([{id: 1, permissions: {delete: true}}])
    view = createIndexView(assignments, open)
    expect(view.options.hasNoQuizzes).toBeFalsy()
  })

  it('sets hasAssignmentQuizzes if has assignment quizzes', () => {
    const assignments = new QuizCollection([{id: 1, permissions: {delete: true}}])
    view = createIndexView(assignments)
    expect(view.options.hasAssignmentQuizzes).toBeTruthy()
  })

  it('sets hasOpenQuizzes if has open quizzes', () => {
    const open = new QuizCollection([{id: 1, permissions: {delete: true}}])
    view = createIndexView(null, open)
    expect(view.options.hasOpenQuizzes).toBeTruthy()
  })

  it('sets hasSurveys if has surveys', () => {
    const surveys = new QuizCollection([{id: 1, permissions: {delete: true}}])
    view = createIndexView(null, null, surveys)
    expect(view.options.hasSurveys).toBeTruthy()
  })

  it("shows modified '+ Quiz' button if quiz lti enabled", () => {
    ENV.flags.quiz_lti_enabled = true
    view = createIndexView()
    const $button = view.$('.choose-quiz-engine')
    expect($button).toHaveLength(1)
  })

  it("does not show modified '+ Quiz' button when quiz lti disabled", () => {
    ENV.flags.quiz_lti_enabled = false
    view = createIndexView()
    expect(view.$('.choose-quiz-engine')).toHaveLength(0)
  })

  it('renders choose quiz engine modal', () => {
    ENV.flags.quiz_lti_enabled = true
    const mockRender = jest.spyOn(ReactDOM, 'render').mockImplementation(() => {})
    view = createIndexView()
    view.$('.choose-quiz-engine').simulate('click')
    expect(mockRender.mock.calls[0][0].props.setOpen).toBe(true)
    mockRender.mockRestore()
  })

  it('should render the view', () => {
    const assignments = new QuizCollection([
      {
        id: 1,
        title: 'Foo Title',
        permissions: {delete: true},
      },
      {
        id: 2,
        title: 'Bar Title',
        permissions: {delete: true},
      },
    ])
    const open = new QuizCollection([
      {
        id: 3,
        title: 'Foo Title',
        permissions: {delete: true},
      },
      {
        id: 4,
        title: 'Bar Title',
        permissions: {delete: true},
      },
    ])
    view = createIndexView(assignments, open)
    view.render()
    expect(view.$el.find('.collectionViewItems li.quiz')).toHaveLength(4)
  })

  it('should filter by search term', () => {
    const assignments = new QuizCollection([
      {
        id: 1,
        title: 'Foo Name',
        permissions: {delete: true},
      },
      {
        id: 2,
        title: 'Bar Title',
        permissions: {delete: true},
      },
    ])

    const assignmentView = new QuizItemGroupView({
      collection: assignments,
      title: 'Assignment Quizzes',
      listId: 'assignment-quizzes',
      isSurvey: false,
    })

    assignmentView.$el.appendTo(fixtures)
    assignmentView.render()

    // Initial count should be 2
    expect(assignmentView.$el.find('.ig-list.collectionViewItems li.quiz')).toHaveLength(2)

    // Filter for 'Foo'
    assignmentView.filterResults('Foo')

    // After filtering, only one quiz should be visible
    const visibleQuizzes = assignmentView.$el
      .find('.ig-list.collectionViewItems li.quiz')
      .filter((_i, el) => !$(el).hasClass('hidden'))
    expect(visibleQuizzes).toHaveLength(1)
  })
})
