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

import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import PublishIconView from '@canvas/publish-icon-view'
import Quiz from '@canvas/quizzes/backbone/models/Quiz'
import fakeENV from '@canvas/test-utils/fakeENV'
import {assignLocation} from '@canvas/util/globalUtils'
import $ from 'jquery'
import QuizItemView from '../QuizItemView'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

// Mock jQuery methods
$.fn.tooltip = jest.fn()
$.fn.simulate = jest.fn()

// Mock window.confirm
const originalConfirm = window.confirm
beforeAll(() => {
  window.confirm = jest.fn(() => true)
})

afterAll(() => {
  window.confirm = originalConfirm
})

const createQuiz = (options = {}) => {
  const permissions = {
    delete: true,
    ...options.permissions,
  }
  return new Quiz({
    permissions,
    ...options,
  })
}

const createView = (quiz, options = {}) => {
  if (!quiz) {
    quiz = createQuiz({
      id: 1,
      title: 'Foo',
    })
  }

  const icon = new PublishIconView({model: quiz})

  ENV.PERMISSIONS = {
    manage: options.canManage,
    create: options.canCreate || options.canManage,
  }
  ENV.FEATURES = ENV.FEATURES || {}

  ENV.FLAGS = {
    post_to_sis_enabled: options.post_to_sis,
    migrate_quiz_enabled: options.migrate_quiz_enabled,
    DIRECT_SHARE_ENABLED: options.DIRECT_SHARE_ENABLED || false,
    quiz_lti_enabled: !!options.quiz_lti_enabled,
    show_additional_speed_grader_link: true,
  }

  ENV.context_asset_string = 'course_1'
  ENV.SHOW_SPEED_GRADER_LINK = true

  const view = new QuizItemView({model: quiz, publishIconView: icon})
  const $fixtures = $('<div id="fixtures" />').appendTo(document.body)
  view.$el.appendTo($fixtures)

  // Set up assign-to link
  if (options.canManage) {
    const assignToLink = $(`
      <div class="assign-to-link">
        <a href="#" data-quiz-context-id="1" data-quiz-name="${quiz.get(
          'title',
        )}" data-quiz-id="${quiz.get('id')}">
          Assign To...
        </a>
      </div>
    `)
    view.$el.append(assignToLink)
  }

  return view.render()
}

describe('QuizItemView', () => {
  let $fixtures

  beforeEach(() => {
    $fixtures = $('<div id="fixtures" />').appendTo(document.body)
    fakeENV.setup({
      CONDITIONAL_RELEASE_ENV: {
        active_rules: [
          {
            trigger_assignment_id: '1',
            scoring_ranges: [
              {
                assignment_sets: [{assignment_set_associations: [{assignment_id: '2'}]}],
              },
            ],
          },
        ],
      },
    })
    CyoeHelper.reloadEnv()
  })

  afterEach(() => {
    $fixtures.remove()
    fakeENV.teardown()
  })

  it('renders admin controls when canManage is true', () => {
    const quiz = createQuiz({id: 1, title: 'Foo'})
    const view = createView(quiz, {canManage: true})
    expect(view.$('.ig-admin')).toHaveLength(1)
  })

  it('does not render admin controls when canManage is false and canDelete is false', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', permissions: {delete: false}})
    const view = createView(quiz, {canManage: false})
    expect(view.$('.ig-admin')).toHaveLength(0)
  })

  it('renders SpeedGrader link when canManage is true and assignment_id exists', () => {
    const quiz = createQuiz({id: 1, title: 'Pancake', assignment_id: '55'})
    const view = createView(quiz, {canManage: true})
    expect(view.$('.speed-grader-link')).toHaveLength(1)
  })

  it('does not render SpeedGrader link when no assignment_id exists', () => {
    const quiz = createQuiz({id: 1, title: 'French Toast'})
    const view = createView(quiz, {canManage: true})
    expect(view.$('.speed-grader-link')).toHaveLength(0)
  })

  it('hides SpeedGrader link when quiz is not published', () => {
    const quiz = createQuiz({id: 1, title: 'Crepe', assignment_id: '31', published: false})
    const view = createView(quiz, {canManage: true})
    expect(view.$('.speed-grader-link-container').attr('class')).toContain('hidden')
  })

  it('has correct SpeedGrader link for regular quizzes', () => {
    const quiz = createQuiz({id: 1, title: 'Waffle', assignment_id: '80'})
    const view = createView(quiz, {canManage: true})
    expect(view.$('.speed-grader-link')[0].href).toContain(
      '/courses/1/gradebook/speed_grader?assignment_id=80',
    )
  })

  it('has correct SpeedGrader link for new quizzes', () => {
    const quiz = createQuiz({
      id: 1,
      title: 'Waffle',
      assignment_id: '32',
      quiz_type: 'quizzes.next',
    })
    const view = createView(quiz, {canManage: true})
    expect(view.$('.speed-grader-link')[0].href).toContain(
      '/courses/1/gradebook/speed_grader?assignment_id=32',
    )
  })

  it.skip('can assign assignment when flag is on and has edit permissions', () => {
    const quiz = createQuiz({id: 1, title: 'Foo'})
    const view = createView(quiz, {
      canManage: true,
    })
    expect(view.$('.assign-to-link')).toHaveLength(1)
  })

  it('cannot assign assignment without edit permissions', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
    const view = createView(quiz, {
      canManage: false,
    })
    expect(view.$('.assign-to-link')).toHaveLength(0)
  })

  it('renders Migrate Button when migrateQuizEnabled is true', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
    const view = createView(quiz, {canManage: true, migrate_quiz_enabled: true})
    expect(view.$('.migrate')).toHaveLength(1)
  })

  it('does not render Migrate Button when migrateQuizEnabled is false', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
    const view = createView(quiz, {canManage: true, migrate_quiz_enabled: false})
    expect(view.$('.migrate')).toHaveLength(0)
  })

  it('shows solid quiz icon for new quizzes', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'quizzes.next'})
    const view = createView(quiz, {canManage: true})
    expect(view.$('i.icon-quiz.icon-Solid')).toHaveLength(1)
  })

  it('shows line quiz icon for old quizzes', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
    const view = createView(quiz, {canManage: true})
    expect(view.$('i.icon-quiz:not(.icon-Solid)')).toHaveLength(1)
  })

  it('initializes sis toggle when post to sis is enabled', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, published: true})
    quiz.set('post_to_sis', true)
    const view = createView(quiz, {canManage: true, post_to_sis: true})
    expect(view.sisButtonView).toBeTruthy()
  })

  describe('delete functionality', () => {
    it('confirms before deleting', () => {
      const quiz = createQuiz({id: 1, title: 'Foo'})
      const view = createView(quiz, {canManage: true})

      const deleteButton = view.$('.delete-item')[0]
      $(deleteButton).trigger('click')
      expect(window.confirm).toHaveBeenCalled()
    })

    it('deletes quiz when confirmed', () => {
      const quiz = createQuiz({id: 1, title: 'Foo'})
      let destroyed = false
      quiz.destroy = () => {
        destroyed = true
      }
      const view = createView(quiz, {canManage: true})

      const deleteButton = view.$('.delete-item')[0]
      $(deleteButton).trigger('click')
      expect(destroyed).toBe(true)
    })
  })

  describe('navigation', () => {
    it('does not redirect when clicking admin area', () => {
      const quiz = createQuiz({id: 1, title: 'Foo'})
      let redirected = false
      quiz.redirectTo = () => {
        redirected = true
      }
      const view = createView(quiz, {canManage: true})

      const adminArea = view.$('.ig-admin')[0]
      $(adminArea).trigger('click')
      expect(redirected).toBe(false)
    })

    it('redirects when clicking details area', () => {
      const quiz = createQuiz({id: 1, title: 'Foo'})
      const view = createView(quiz, {canManage: true})

      // Add href to title link to simulate real behavior
      view.$('.ig-title').attr('href', '/courses/1/quizzes/1')

      const detailsArea = view.$('.ig-details')[0]
      $(detailsArea).trigger('click')

      expect(assignLocation).toHaveBeenCalledWith('/courses/1/quizzes/1')
    })
  })
})
