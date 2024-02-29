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
import QuizItemView from 'ui/features/quizzes_index/backbone/views/QuizItemView'
import PublishIconView from '@canvas/publish-icon-view'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import assertions from 'helpers/assertions'
import '@canvas/jquery/jquery.simulate'
import ReactDOM from 'react-dom'

const createQuiz = function (options = {}) {
  const permissions = {
    delete: true,
    ...options.permissions,
  }
  return new Quiz({
    permissions,
    ...options,
  })
}

const createView = function (quiz, options = {}) {
  if (quiz == null) {
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

  ENV.FLAGS = {
    post_to_sis_enabled: options.post_to_sis,
    migrate_quiz_enabled: options.migrate_quiz_enabled,
    DIRECT_SHARE_ENABLED: options.DIRECT_SHARE_ENABLED || false,
    quiz_lti_enabled: !!options.quiz_lti_enabled,
    show_additional_speed_grader_link: true,
  }

  ENV.context_asset_string = 'course_1'
  ENV.SHOW_SPEED_GRADER_LINK = true
  ENV.FEATURES.differentiated_modules = options.differentiated_modules

  const view = new QuizItemView({model: quiz, publishIconView: icon})
  view.$el.appendTo($('#fixtures'))
  return view.render()
}

QUnit.module('QuizItemView', {
  setup() {
    this.ajaxStub = sandbox.stub($, 'ajaxJSON')
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
  },
  teardown() {
    fakeENV.teardown()
  },
})

// eslint-disable-next-line qunit/resolve-async
test('it should be accessible', assert => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz)
  const done = assert.async()
  return assertions.isAccessible(view, done, {a11yReport: true})
})

test('renders admin if canManage', () => {
  const quiz = createQuiz({id: 1, title: 'Foo'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin').length, 1)
})

test('does not render admin if canManage and canDelete is false', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', permissions: {delete: false}})
  const view = createView(quiz, {canManage: false})
  equal(view.$('.ig-admin').length, 0)
})

test('renders link to speed grader if canManage and assignment_id', () => {
  const quiz = createQuiz({id: 1, title: 'Pancake', assignment_id: '55'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('.speed-grader-link').length, 1)
})

test('does NOT render speed grader link if no assignment_id', () => {
  const quiz = createQuiz({id: 1, title: 'French Toast'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('.speed-grader-link').length, 0)
})

test('hides speed grader link if quiz is not published', () => {
  const quiz = createQuiz({id: 1, title: 'Crepe', assignment_id: '31', published: false})
  const view = createView(quiz, {canManage: true})
  ok(view.$('.speed-grader-link-container').attr('class').includes('hidden'))
})

test('speed grader link is correct', () => {
  const quiz = createQuiz({id: 1, title: 'Waffle', assignment_id: '80'})
  const view = createView(quiz, {canManage: true})
  ok(
    view
      .$('.speed-grader-link')[0]
      .href.includes('/courses/1/gradebook/speed_grader?assignment_id=80')
  )
})

test('speed grader link is correct for new quizzes', () => {
  const quiz = createQuiz({id: 1, title: 'Waffle', assignment_id: '32', quiz_type: 'quizzes.next'})
  const view = createView(quiz, {canManage: true})
  ok(
    view
      .$('.speed-grader-link')[0]
      .href.includes('/courses/1/gradebook/speed_grader?assignment_id=32')
  )
})

test('can assign assignment if flag is on and has edit permissions', function () {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {
    canManage: true,
    differentiated_modules: true,
  })
  equal(view.$('.assign-to-link').length, 1)
})

test('cannot assign assignment if no edit permissions', function () {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {
    canManage: false,
    differentiated_modules: true,
  })
  equal(view.$('.assign-to-link').length, 0)
})

test('cannot assign assignment if flag is off', function () {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {
    canManage: true,
    differentiated_modules: false,
  })
  equal(view.$('.assign-to-link').length, 0)
})

test('renders Migrate Button if migrateQuizEnabled is true', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true, migrate_quiz_enabled: true})
  equal(view.$('.migrate').length, 1)
})

test('does not render Migrate Button if migrateQuizEnabled is false', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true, migrate_quiz_enabled: false})
  equal(view.$('.migrate').length, 0)
})

test('shows solid quiz icon for new.quizzes', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'quizzes.next'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('i.icon-quiz.icon-Solid').length, 1)
})

test('shows a teacher a line quiz icon for old quizzes', () => {
  Object.assign(window.ENV, {current_user_roles: ['teacher', 'student']})
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true, migrate_quiz_enabled: false})
  equal(view.$('i.icon-quiz').length, 1)
  equal(view.$('i.icon-quiz.icon-Solid').length, 0)
})

test('shows a student a solid quiz icon for old quizzes', () => {
  Object.assign(window.ENV, {current_user_roles: ['student']})
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: false, migrate_quiz_enabled: false})
  equal(view.$('i.icon-quiz.icon-Solid').length, 1)
})

test('#migrateQuiz is called', function () {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true, migrate_quiz_enabled: false})
  const event = new $.Event()
  view.migrateQuiz(event)
  ok(this.ajaxStub.called)
})

test('initializes sis toggle if post to sis enabled', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, published: true})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: true, post_to_sis: true})
  ok(view.sisButtonView)
})

test('initializes sis toggle if post to sis disabled', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, published: true})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: true, post_to_sis: true})
  ok(view.sisButtonView)
})

test('does not initialize sis toggle if post_to_sis feature disabled', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, published: true})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: true, post_to_sis: false})
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if post to sis is null', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  quiz.set('post_to_sis', null)
  const view = createView(quiz, {canManage: true})
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled but can't manage", () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: false})
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled, can't manage and is unpublished", () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: false})
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis disabled, can't manage and is unpublished", () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: false})
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if sis enabled, can manage and is unpublished', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: true})
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if sis disabled, can manage and is unpublished', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: true})
  ok(!view.sisButtonView)
})

test('udpates publish status when model changes', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', published: false})
  const view = createView(quiz)

  ok(!view.$el.find('.ig-row').hasClass('ig-published'))

  quiz.set('published', true)
  ok(view.$el.find('.ig-row').hasClass('ig-published'))
})

test('cannot delete quiz without delete permissions', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, permissions: {delete: false}})
  const view = createView(quiz)

  sandbox.spy(quiz, 'destroy')
  sandbox.spy(window, 'confirm')

  view.$('.delete-item').simulate('click')
  notOk(window.confirm.called)
  notOk(quiz.destroy.called)
})

test('prompts confirm for delete', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true})
  quiz.destroy = () => true

  sandbox.stub(window, 'confirm').returns(true)

  view.$('.delete-item').simulate('click')
  ok(window.confirm.called)
})

test('confirm delete destroys model', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true})

  let destroyed = false
  quiz.destroy = () => (destroyed = true)
  sandbox.stub(window, 'confirm').returns(true)

  view.$('.delete-item').simulate('click')
  ok(destroyed)
})

test('does not redirect if clicking on ig-admin area', () => {
  const quiz = createQuiz({id: 1, title: 'Foo', permissions: {delete: false}})
  const view = createView(quiz)

  let redirected = false
  view.redirectTo = () => (redirected = true)

  view.$('.ig-admin').simulate('click')
  ok(!redirected)
})

test('follows through when clicking on row', () => {
  const view = createView()

  let redirected = false
  view.redirectTo = () => (redirected = true)

  view.$('.ig-details').simulate('click')
  ok(redirected)
})

test('renders lockAt/unlockAt for multiple due dates', () => {
  const quiz = createQuiz({
    id: 1,
    title: 'mdd',
    all_dates: [{due_at: new Date()}, {due_at: new Date()}],
  })
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('renders lockAt/unlockAt when locked', () => {
  const future = new Date()
  future.setDate(future.getDate() + 10)
  const quiz = createQuiz({id: 1, title: 'mdd', unlock_at: future.toISOString()})
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('renders lockAt/unlockAt when locking in future', () => {
  const past = new Date()
  past.setDate(past.getDate() - 10)
  const future = new Date()
  future.setDate(future.getDate() + 10)
  const quiz = createQuiz({
    id: 1,
    title: 'unlock later',
    unlock_at: past.toISOString(),
    lock_at: future.toISOString(),
  })
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('does not render lockAt/unlockAt when not locking in future', () => {
  const past = new Date()
  past.setDate(past.getDate() - 10)
  const quiz = createQuiz({id: 1, title: 'unlocked for good', unlock_at: past.toISOString()})
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, false)
})

test('does not render mastery paths menu option for quiz if cyoe off', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'assignment'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('renders mastery paths menu option for assignment quiz if cyoe on', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({
    id: 1,
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
    assignment_id: '2',
  })
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 1)
})

test('does not render mastery paths menu option for survey quiz if cyoe on', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'survey'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('does not render mastery paths menu option for graded survey quiz if cyoe on', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'graded_survey'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('does not render mastery paths menu option for practice quiz if cyoe on', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'practice_quiz'})
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('does not render mastery paths link for quiz if cyoe off', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const quiz = createQuiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
  })
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('does not render mastery paths link for quiz if quiz does not have a rule', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({
    id: 1,
    assignment_id: '2',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
  })
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('renders mastery paths link for quiz if quiz has a rule', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
  })
  const view = createView(quiz, {canManage: true})
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 1)
})

test('does not render mastery paths icon for quiz if cyoe off', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const quiz = createQuiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
  })
  const view = createView(quiz, {canManage: true})
  equal(view.$('.mastery-path-icon').length, 0)
})

test('does not render mastery paths icon for quiz if quiz is not released by a rule', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
  })
  const view = createView(quiz, {canManage: true})
  equal(view.$('.mastery-path-icon').length, 0)
})

test('renders mastery paths link for quiz if quiz has is released by a rule', () => {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = createQuiz({
    id: 1,
    assignment_id: '2',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
  })
  const view = createView(quiz, {canManage: true})
  equal(view.$('.mastery-path-icon').length, 1)
})

test('can duplicate when a quiz can be duplicated', () => {
  const quiz = createQuiz({
    id: 1,
    title: 'Foo',
    can_duplicate: true,
    can_update: true,
  })
  Object.assign(window.ENV, {current_user_roles: ['admin']})
  const view = createView(quiz, {canManage: true})
  const json = view.toJSON()
  ok(json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 1)
})

test('duplicate option is not available when a quiz can not be duplicated (old quizzes)', () => {
  const quiz = createQuiz({
    id: 1,
    title: 'Foo',
    can_update: true,
  })
  Object.assign(window.ENV, {current_user_roles: ['admin']})
  const view = createView(quiz, {})
  const json = view.toJSON()
  ok(!json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 0)
})

test('can skip to build', () => {
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
  const json = view.toJSON()
  ok(json.canShowQuizBuildShortCut)
  equal(view.$('a.icon-quiz').length, 1)
})

test('clicks on Retry button to trigger another duplicating request', () => {
  const quiz = createQuiz({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate',
  })
  const dfd = $.Deferred()
  const view = createView(quiz)
  sandbox.stub(quiz, 'duplicate_failed').returns(dfd)
  view.$(`.duplicate-failed-retry`).simulate('click')
  ok(quiz.duplicate_failed.called)
})

test('clicks on Retry button to trigger another migrating request', () => {
  const quiz = createQuiz({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_migrate',
  })
  const dfd = $.Deferred()
  const view = createView(quiz)
  sandbox.stub(quiz, 'retry_migration').returns(dfd)
  view.$(`.migrate-failed-retry`).simulate('click')
  ok(quiz.retry_migration.called)
})

test('can duplicate when a user has permissons to create quizzes', () => {
  const quiz = createQuiz({
    id: 1,
    title: 'Foo',
    can_duplicate: true,
    can_update: true,
  })
  Object.assign(window.ENV, {current_user_roles: ['teacher']})
  const view = createView(quiz, {canManage: true})
  const json = view.toJSON()
  ok(json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 1)
})

test('cannot duplicate when user is not admin', () => {
  const quiz = createQuiz({
    id: 1,
    title: 'Foo',
    can_duplicate: true,
    can_update: true,
  })
  Object.assign(window.ENV, {current_user_roles: ['user']})
  const view = createView(quiz, {})
  const json = view.toJSON()
  ok(!json.canDuplicate)
  equal(view.$('.duplicate_assignment').length, 0)
})

test('displays duplicating message when assignment is duplicating', () => {
  const quiz = createQuiz({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'duplicating',
  })
  const view = createView(quiz)
  ok(view.$el.text().includes('Making a copy of "Foo"'))
})

test('displays failed to duplicate message when assignment failed to duplicate', () => {
  const quiz = createQuiz({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate',
  })
  const view = createView(quiz)
  ok(view.$el.text().includes('Something went wrong with making a copy of "Foo"'))
})

test('does not display cancel button when quiz failed to duplicate is blueprint', () => {
  const quiz = createQuiz({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate',
    migration_id: 'mastercourse_xxxxxxx',
  })
  const view = createView(quiz)
  strictEqual(view.$('button.duplicate-failed-cancel.btn').length, 0)
})

test('displays cancel button when quiz failed to duplicate is not blueprint', () => {
  const quiz = createQuiz({
    id: 2,
    title: 'Foo Copy',
    original_assignment_name: 'Foo',
    workflow_state: 'failed_to_duplicate',
  })
  const view = createView(quiz)
  ok(view.$('button.duplicate-failed-cancel.btn').text().includes('Cancel'))
})

QUnit.module('direct share', hooks => {
  hooks.beforeEach(() => {
    $('<div id="direct-share-mount-point">').appendTo('#fixtures')
    fakeENV.setup({COURSE_ID: 123})
    sinon.stub(ReactDOM, 'render')
  })

  hooks.afterEach(() => {
    ReactDOM.render.restore()
    fakeENV.teardown()
    $('#direct-share-mount-point').remove()
  })

  test('does not render direct share menu items when not DIRECT_SHARE_ENABLED', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
    const view = createView(quiz)
    equal(view.$('.quiz-copy-to').length, 0)
    equal(view.$('.quiz-send-to').length, 0)
  })

  test('renders direct share menu items when DIRECT_SHARE_ENABLED', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
    const view = createView(quiz, {DIRECT_SHARE_ENABLED: true})
    equal(view.$('.quiz-copy-to').length, 1)
    equal(view.$('.quiz-send-to').length, 1)
  })

  test('opens and closes the Copy To tray', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
    const view = createView(quiz, {DIRECT_SHARE_ENABLED: true})
    view.$(`.al-trigger`).simulate('click')
    view.$(`.quiz-copy-to`).simulate('click')
    const args = ReactDOM.render.firstCall.args
    equal(args[0].props.open, true)
    equal(args[0].props.sourceCourseId, 123)
    deepEqual(args[0].props.contentSelection, {quizzes: [1]})

    clearTimeout(args[0].props.onDismiss())
    equal(ReactDOM.render.lastCall.args[0].props.open, false)
  })

  test('uses the correct content_type for new quizzes on Copy To', () => {
    const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'quizzes.next'})
    const view = createView(quiz, {DIRECT_SHARE_ENABLED: true})
    view.$(`.al-trigger`).simulate('click')
    view.$(`.quiz-copy-to`).simulate('click')
    const args = ReactDOM.render.firstCall.args
    equal(args[0].props.open, true)
    equal(args[0].props.sourceCourseId, 123)
    deepEqual(args[0].props.contentSelection, {assignments: [1]})

    clearTimeout(args[0].props.onDismiss())
    equal(ReactDOM.render.lastCall.args[0].props.open, false)
  })

  test('opens and closes the Send To tray', () => {
    const quiz = createQuiz({id: '1', title: 'Foo', can_update: true})
    const view = createView(quiz, {DIRECT_SHARE_ENABLED: true})
    view.$(`.al-trigger`).simulate('click')
    view.$(`.quiz-send-to`).simulate('click')
    const args = ReactDOM.render.firstCall.args
    equal(args[0].props.open, true)
    equal(args[0].props.sourceCourseId, 123)
    deepEqual(args[0].props.contentShare, {content_type: 'quiz', content_id: '1'})

    clearTimeout(args[0].props.onDismiss())
    equal(ReactDOM.render.lastCall.args[0].props.open, false)
  })

  test('uses the correct content_type for new quizzes on Send To', () => {
    const quiz = createQuiz({id: '1', title: 'Foo', can_update: true, quiz_type: 'quizzes.next'})
    const view = createView(quiz, {DIRECT_SHARE_ENABLED: true})
    view.$(`.al-trigger`).simulate('click')
    view.$(`.quiz-send-to`).simulate('click')
    const args = ReactDOM.render.firstCall.args
    equal(args[0].props.open, true)
    equal(args[0].props.sourceCourseId, 123)
    deepEqual(args[0].props.contentShare, {content_type: 'assignment', content_id: '1'})

    clearTimeout(args[0].props.onDismiss())
    equal(ReactDOM.render.lastCall.args[0].props.open, false)
  })
})

QUnit.module('Quiz#quizzesRespondusEnabled', hooks => {
  hooks.beforeEach(() => {
    fakeENV.setup({current_user_roles: []})
  })

  hooks.afterEach(() => {
    fakeENV.teardown()
  })

  test('returns false if the assignment is not RLDB enabled', () => {
    fakeENV.setup({current_user_roles: ['student']})
    const quiz = createQuiz({
      id: 1,
      quiz_type: 'quizzes.next',
      require_lockdown_browser: false,
    })
    const view = createView(quiz)
    const json = view.toJSON()
    equal(json.quizzesRespondusEnabled, false)
  })

  test('returns false if the assignment is not a N.Q assignment', () => {
    fakeENV.setup({current_user_roles: ['student']})
    const quiz = createQuiz({
      id: 1,
      quiz_type: 'practice',
      require_lockdown_browser: true,
    })
    const view = createView(quiz)
    const json = view.toJSON()
    equal(json.quizzesRespondusEnabled, false)
  })

  test('returns false if the user is not a student', () => {
    fakeENV.setup({current_user_roles: ['teacher']})
    const quiz = createQuiz({
      id: 1,
      quiz_type: 'quizzes.next',
      require_lockdown_browser: true,
    })
    const view = createView(quiz)
    const json = view.toJSON()
    equal(json.quizzesRespondusEnabled, false)
  })

  test('returns true if the assignment is a RLDB enabled N.Q', () => {
    fakeENV.setup({current_user_roles: ['student']})
    const quiz = createQuiz({
      id: 1,
      quiz_type: 'quizzes.next',
      require_lockdown_browser: true,
    })
    const view = createView(quiz)
    const json = view.toJSON()
    equal(json.quizzesRespondusEnabled, true)
  })
})

QUnit.module('Blueprint Icon/Button', _hooks => {
  test('renders unlocked', () => {
    const quiz = createQuiz({
      id: 1,
      title: 'Foo',
      is_master_course_master_content: true,
      restricted_by_master_course: false,
      can_update: true,
    })
    const view = createView(quiz, {canManage: true})
    equal(view.$('.lock-icon.btn-unlocked i.icon-blueprint').length, 1)
  })

  test('renders locked', () => {
    const quiz = createQuiz({
      id: 1,
      title: 'Foo',
      is_master_course_master_content: true,
      restricted_by_master_course: true,
      can_update: true,
    })
    const view = createView(quiz, {canManage: true})
    equal(view.$('.lock-icon.lock-icon-locked i.icon-blueprint-lock').length, 1)
  })
})
