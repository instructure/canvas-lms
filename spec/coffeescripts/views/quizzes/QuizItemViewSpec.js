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
import QuizItemView from 'compiled/views/quizzes/QuizItemView'
import PublishIconView from 'compiled/views/PublishIconView'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'
import CyoeHelper from 'jsx/shared/conditional_release/CyoeHelper'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

const fixtures = $('#fixtures')

const createQuiz = function(options = {}) {
  const permissions = {
    delete: true,
    ...options.permissions
  }
  return new Quiz({
    permissions,
    ...options
  })
}

const createView = function(quiz, options = {}) {
  if (quiz == null) {
    quiz = createQuiz({
      id: 1,
      title: 'Foo'
    })
  }

  const icon = new PublishIconView({model: quiz})

  ENV.PERMISSIONS = {
    manage: options.canManage
  }

  ENV.FLAGS = {
    post_to_sis_enabled: options.post_to_sis,
    migrate_quiz_enabled: options.migrate_quiz_enabled
  }

  const view = new QuizItemView({model: quiz, publishIconView: icon})
  view.$el.appendTo($('#fixtures'))
  return view.render()
}

QUnit.module('QuizItemView', {
  setup() {
    this.ajaxStub = this.stub($, 'ajaxJSON')
    fakeENV.setup({
      CONDITIONAL_RELEASE_ENV: {
        active_rules: [
          {
            trigger_assignment: '1',
            scoring_ranges: [
              {
                assignment_sets: [{assignments: [{assignment_id: '2'}]}]
              }
            ]
          }
        ]
      }
    })
    CyoeHelper.reloadEnv()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('it should be accessible', function(assert) {
  const quiz = new Quiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz)
  const done = assert.async()
  return assertions.isAccessible(view, done, {a11yReport: true})
})

test('renders admin if can_update', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz)
  equal(view.$('.ig-admin').length, 1)
})

test('doesnt render admin if can_update is false', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false})
  const view = createView(quiz)
  equal(view.$('.ig-admin').length, 0)
})

test('renders Migrate Button if post to migrateQuizEnabled is true', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true, migrate_quiz_enabled: true})
  equal(view.$('.migrate').length, 1)
})

test('does not render Migrate Button if migrateQuizEnabled is false', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true, migrate_quiz_enabled: false})
  equal(view.$('.migrate').length, 0)
})

test('#migrateQuiz is called', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz, {canManage: true, migrate_quiz_enabled: false})
  const event = new jQuery.Event()
  view.migrateQuiz(event)
  ok(this.ajaxStub.called)
})

test('initializes sis toggle if post to sis enabled', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, published: true})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: true, post_to_sis: true})
  ok(view.sisButtonView)
})

test('initializes sis toggle if post to sis disabled', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, published: true})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: true, post_to_sis: true})
  ok(view.sisButtonView)
})

test('does not initialize sis toggle if post_to_sis feature option disabled', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, published: true})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: true, post_to_sis: false})
  console.log('end spec')
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if post to sis is null', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  quiz.set('post_to_sis', null)
  const view = createView(quiz, {canManage: true})
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled but can't manage", function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: false})
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis enabled, can't manage and is unpublished", function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: false})
  ok(!view.sisButtonView)
})

test("does not initialize sis toggle if sis disabled, can't manage and is unpublished", function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: false})
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if sis enabled, can manage and is unpublished', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', true)
  const view = createView(quiz, {canManage: true})
  ok(!view.sisButtonView)
})

test('does not initialize sis toggle if sis disabled, can manage and is unpublished', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: false, published: false})
  quiz.set('post_to_sis', false)
  const view = createView(quiz, {canManage: true})
  ok(!view.sisButtonView)
})

test('udpates publish status when model changes', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', published: false})
  const view = createView(quiz)

  ok(!view.$el.find('.ig-row').hasClass('ig-published'))

  quiz.set('published', true)
  ok(view.$el.find('.ig-row').hasClass('ig-published'))
})

test('cannot delete quiz without delete permissions', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true, permissions: {delete: false}})
  const view = createView(quiz)

  this.spy(quiz, 'destroy')
  this.spy(window, 'confirm')

  view.$('.delete-item').simulate('click')
  notOk(window.confirm.called)
  notOk(quiz.destroy.called)
})

test('prompts confirm for delete', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz)
  quiz.destroy = () => true

  this.stub(window, 'confirm').returns(true)

  view.$('.delete-item').simulate('click')
  ok(window.confirm.called)
})

test('confirm delete destroys model', function() {
  const quiz = createQuiz({id: 1, title: 'Foo', can_update: true})
  const view = createView(quiz)

  let destroyed = false
  quiz.destroy = () => (destroyed = true)
  this.stub(window, 'confirm').returns(true)

  view.$('.delete-item').simulate('click')
  ok(destroyed)
})

test('doesnt redirect if clicking on ig-admin area', function() {
  const view = createView()

  let redirected = false
  view.redirectTo = () => (redirected = true)

  view.$('.ig-admin').simulate('click')
  ok(!redirected)
})

test('follows through when clicking on row', function() {
  const view = createView()

  let redirected = false
  view.redirectTo = () => (redirected = true)

  view.$('.ig-details').simulate('click')
  ok(redirected)
})

test('renders lockAt/unlockAt for multiple due dates', function() {
  const quiz = createQuiz({
    id: 1,
    title: 'mdd',
    all_dates: [{due_at: new Date()}, {due_at: new Date()}]
  })
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('renders lockAt/unlockAt when locked', function() {
  const future = new Date()
  future.setDate(future.getDate() + 10)
  const quiz = createQuiz({id: 1, title: 'mdd', unlock_at: future.toISOString()})
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('renders lockAt/unlockAt when locking in future', function() {
  const past = new Date()
  past.setDate(past.getDate() - 10)
  const future = new Date()
  future.setDate(future.getDate() + 10)
  const quiz = createQuiz({
    id: 1,
    title: 'unlock later',
    unlock_at: past.toISOString(),
    lock_at: future.toISOString()
  })
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, true)
})

test('does not render lockAt/unlockAt when not locking in future', function() {
  const past = new Date()
  past.setDate(past.getDate() - 10)
  const quiz = createQuiz({id: 1, title: 'unlocked for good', unlock_at: past.toISOString()})
  const view = createView(quiz)
  const json = view.toJSON()
  equal(json.showAvailability, false)
})

test('does not render mastery paths menu option for quiz if cyoe off', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const quiz = new Quiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'assignment'})
  const view = createView(quiz)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('renders mastery paths menu option for assignment quiz if cyoe on', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({
    id: 1,
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment',
    assignment_id: '2'
  })
  const view = createView(quiz)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 1)
})

test('does not render mastery paths menu option for survey quiz if cyoe on', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'survey'})
  const view = createView(quiz)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('does not render mastery paths menu option for graded survey quiz if cyoe on', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'graded_survey'})
  const view = createView(quiz)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('does not render mastery paths menu option for practice quiz if cyoe on', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({id: 1, title: 'Foo', can_update: true, quiz_type: 'practice_quiz'})
  const view = createView(quiz)
  equal(view.$('.ig-admin .al-options .icon-mastery-path').length, 0)
})

test('does not render mastery paths link for quiz if cyoe off', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const quiz = new Quiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment'
  })
  const view = createView(quiz)
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('does not render mastery paths link for quiz if quiz does not have a rule', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({
    id: 1,
    assignment_id: '2',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment'
  })
  const view = createView(quiz)
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0)
})

test('renders mastery paths link for quiz if quiz has a rule', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment'
  })
  const view = createView(quiz)
  equal(view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 1)
})

test('does not render mastery paths icon for quiz if cyoe off', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const quiz = new Quiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment'
  })
  const view = createView(quiz)
  equal(view.$('.mastery-path-icon').length, 0)
})

test('does not render mastery paths icon for quiz if quiz is not released by a rule', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({
    id: 1,
    assignment_id: '1',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment'
  })
  const view = createView(quiz)
  equal(view.$('.mastery-path-icon').length, 0)
})

test('renders mastery paths link for quiz if quiz has is released by a rule', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
  const quiz = new Quiz({
    id: 1,
    assignment_id: '2',
    title: 'Foo',
    can_update: true,
    quiz_type: 'assignment'
  })
  const view = createView(quiz)
  equal(view.$('.mastery-path-icon').length, 1)
})
