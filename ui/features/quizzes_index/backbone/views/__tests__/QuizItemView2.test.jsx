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

import $ from 'jquery'
import Quiz from '@canvas/quizzes/backbone/models/Quiz'
import QuizItemView from '../QuizItemView'
import PublishIconView from '@canvas/publish-icon-view'
import fakeENV from '@canvas/test-utils/fakeENV'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'

// Mock jQuery methods
$.fn.tooltip = jest.fn()
$.fn.simulate = jest.fn()

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

  describe('mastery paths menu option', () => {
    it('does not render for quiz if cyoe off', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
      const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'assignment'})
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(0)
    })

    it('renders for assignment quiz if cyoe on', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({
        id: 1,
        title: 'Foo',
        can_update: true,
        quiz_type: 'assignment',
        assignment_id: '2',
      })
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(1)
    })

    it('does not render for survey quiz if cyoe on', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'survey'})
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(0)
    })

    it('does not render for graded survey quiz if cyoe on', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'graded_survey'})
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(0)
    })

    it('does not render for practice quiz if cyoe on', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'practice_quiz'})
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin .al-options .icon-mastery-path')).toHaveLength(0)
    })
  })

  describe('mastery paths link', () => {
    it('does not render if cyoe off', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
      const quiz = createQuiz({
        id: 1,
        assignment_id: '1',
        title: 'Foo',
        can_update: true,
        quiz_type: 'assignment',
      })
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin > a[href$="#mastery-paths-editor"]')).toHaveLength(0)
    })

    it('does not render if quiz does not have a rule', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({
        id: 1,
        assignment_id: '2',
        title: 'Foo',
        can_update: true,
        quiz_type: 'assignment',
      })
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin > a[href$="#mastery-paths-editor"]')).toHaveLength(0)
    })

    it('renders if quiz has a rule', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({
        id: 1,
        assignment_id: '1',
        title: 'Foo',
        can_update: true,
        quiz_type: 'assignment',
      })
      const view = createView(quiz, {canManage: true})
      expect(view.$('.ig-admin > a[href$="#mastery-paths-editor"]')).toHaveLength(1)
    })
  })

  describe('mastery paths icon', () => {
    it('does not render if cyoe off', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
      const quiz = createQuiz({
        id: 1,
        assignment_id: '1',
        title: 'Foo',
        can_update: true,
        quiz_type: 'assignment',
      })
      const view = createView(quiz, {canManage: true})
      expect(view.$('.mastery-path-icon')).toHaveLength(0)
    })

    it('does not render if quiz is not released by a rule', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({
        id: 1,
        assignment_id: '1',
        title: 'Foo',
        can_update: true,
        quiz_type: 'assignment',
      })
      const view = createView(quiz, {canManage: true})
      expect(view.$('.mastery-path-icon')).toHaveLength(0)
    })

    it('renders if quiz is released by a rule', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      const quiz = createQuiz({
        id: 1,
        assignment_id: '2',
        title: 'Foo',
        can_update: true,
        quiz_type: 'assignment',
      })
      const view = createView(quiz, {canManage: true})
      expect(view.$('.mastery-path-icon')).toHaveLength(1)
    })
  })

  describe('quiz duplication', () => {
    it('can duplicate when a quiz can be duplicated', () => {
      const quiz = createQuiz({
        id: 1,
        title: 'Foo',
        can_duplicate: true,
        can_update: true,
      })
      Object.assign(window.ENV, {current_user_roles: ['admin']})
      const view = createView(quiz, {canManage: true})
      expect(view.$('.duplicate_assignment')).toHaveLength(1)
    })

    it('duplicate option is not available when a quiz cannot be duplicated', () => {
      const quiz = createQuiz({
        id: 1,
        title: 'Foo',
        can_update: true,
        can_duplicate: false,
      })
      Object.assign(window.ENV, {current_user_roles: ['admin']})
      const view = createView(quiz, {})
      expect(view.$('.duplicate_assignment')).toHaveLength(0)
    })

    it('can duplicate when a user has permissions to create quizzes', () => {
      const quiz = createQuiz({
        id: 1,
        title: 'Foo',
        can_duplicate: true,
        can_update: true,
      })
      Object.assign(window.ENV, {current_user_roles: ['teacher']})
      const view = createView(quiz, {canManage: true})
      expect(view.$('.duplicate_assignment')).toHaveLength(1)
    })

    it.skip('cannot duplicate when user is not admin', () => {
      const quiz = createQuiz({
        id: 1,
        title: 'Foo',
        can_duplicate: true,
        can_update: true,
      })
      Object.assign(window.ENV, {current_user_roles: ['user']})
      const view = createView(quiz, {})
      expect(view.$('.duplicate_assignment')).toHaveLength(0)
    })
  })

  describe('quiz build shortcut', () => {
    it('can skip to build', () => {
      const quiz = createQuiz({
        id: 1,
        title: 'Foo',
        can_duplicate: true,
        can_update: true,
        quiz_type: 'quizzes.next',
      })
      Object.assign(window.ENV, {current_user_roles: ['admin']})
      const view = createView(quiz, {
        canManage: true,
        quiz_lti_enabled: true,
      })
      expect(view.$('a.icon-quiz')).toHaveLength(1)
    })
  })

  describe('retry functionality', () => {
    it('clicks on Retry button to trigger another duplicating request', () => {
      const quiz = createQuiz({
        id: 2,
        title: 'Foo Copy',
        original_assignment_name: 'Foo',
        workflow_state: 'failed_to_duplicate',
      })
      const view = createView(quiz)
      const mockDeferred = {
        always: jest.fn().mockReturnThis(),
        then: jest.fn().mockReturnThis(),
      }
      const duplicateFailedSpy = jest.spyOn(quiz, 'duplicate_failed').mockReturnValue(mockDeferred)
      view.$('.duplicate-failed-retry').trigger('click')
      expect(duplicateFailedSpy).toHaveBeenCalled()
    })

    it('clicks on Retry button to trigger another migrating request', () => {
      const quiz = createQuiz({
        id: 2,
        title: 'Foo Copy',
        original_assignment_name: 'Foo',
        workflow_state: 'failed_to_migrate',
      })
      const view = createView(quiz)
      const mockDeferred = {
        always: jest.fn().mockReturnThis(),
        then: jest.fn().mockReturnThis(),
      }
      const retryMigrationSpy = jest.spyOn(quiz, 'retry_migration').mockReturnValue(mockDeferred)
      view.$('.migrate-failed-retry').trigger('click')
      expect(retryMigrationSpy).toHaveBeenCalled()
    })
  })
})
