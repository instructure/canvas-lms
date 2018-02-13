#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'jquery'
  'compiled/views/SisButtonView'
  'Backbone'
], ($, SisButtonView, Backbone) ->

  class AssignmentStub extends Backbone.Model
    url: '/fake'
    postToSIS: (postToSisBoolean) =>
      return @get 'post_to_sis' unless arguments.length > 0
      @set 'post_to_sis', postToSisBoolean

    name: (newName) =>
      return @get 'name' unless arguments.length > 0
      @set 'name', newName

    maxNameLength: =>
      return ENV.MAX_NAME_LENGTH

    dueAt: (date) =>
      return @get 'due_at' unless arguments.length > 0
      @set 'due_at', date

    allDates: (alldate) =>
      return @get 'all_dates' unless arguments.length > 0
      @set 'all_dates', alldate

    sisIntegrationSettingsEnabled: =>
      return ENV.SIS_INTEGRATION_SETTINGS_ENABLED

  class QuizStub extends Backbone.Model
    url: '/fake'
    postToSIS: (postToSisBoolean) =>
      return @get 'post_to_sis' unless arguments.length > 0
      @set 'post_to_sis', postToSisBoolean

    name: (newName) =>
      return @get 'title' unless arguments.length > 0
      @set 'title', newName

    maxNameLength: =>
      return ENV.MAX_NAME_LENGTH

    dueAt: (date) =>
      return @get 'due_at' unless arguments.length > 0
      @set 'due_at', date

    allDates: (alldate) =>
      return @get 'all_dates' unless arguments.length > 0
      @set 'all_dates', alldate

    sisIntegrationSettingsEnabled: =>
      return ENV.SIS_INTEGRATION_SETTINGS_ENABLED

  QUnit.module 'SisButtonView',
    setup: ->
      @assignment = new AssignmentStub()
      @quiz = new QuizStub()
      @quiz.set('toggle_post_to_sis_url', '/some_other_url')

  test 'properly populates initial settings', ->
    @assignment.set('post_to_sis', true)
    @quiz.set('post_to_sis', false)
    @view1 = new SisButtonView(model: @assignment, sisName: 'SIS')
    @view2 = new SisButtonView(model: @quiz, sisName: 'SIS')
    @view1.render()
    @view2.render()
    equal @view1.$input.attr('title'), 'Sync to SIS enabled. Click to toggle.'
    equal @view2.$input.attr('title'), 'Sync to SIS disabled. Click to toggle.'

  test 'properly populates initial settings with custom SIS name', ->
    @assignment.set('post_to_sis', true)
    @quiz.set('post_to_sis', false)
    @view1 = new SisButtonView(model: @assignment, sisName: 'PowerSchool')
    @view2 = new SisButtonView(model: @quiz, sisName: 'PowerSchool')
    @view1.render()
    @view2.render()
    equal @view1.$input.attr('title'), 'Sync to PowerSchool enabled. Click to toggle.'
    equal @view2.$input.attr('title'), 'Sync to PowerSchool disabled. Click to toggle.'

  test 'properly toggles model sis status when clicked', ->
    ENV.MAX_NAME_LENGTH = 256
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @view = new SisButtonView(model: @assignment)
    @view.render()
    @view.$el.click()
    ok @assignment.postToSIS()
    @view.$el.click()
    ok !@assignment.postToSIS()

  test 'model does not save if there are name length errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @view = new SisButtonView(model: @assignment, maxNameLengthRequired: true)
    @view.render()
    @view.$el.click()
    ok !@assignment.postToSIS()

  test 'model saves if there are name length errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is false', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @view = new SisButtonView(model: @assignment, maxNameLengthRequired: false)
    @view.render()
    @view.$el.click()
    ok @assignment.postToSIS()

  test 'model does not save if there are name length errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @view = new SisButtonView(model: @quiz, maxNameLengthRequired: true)
    @view.render()
    @view.$el.click()
    ok !@quiz.postToSIS()

  test 'model saves if there are name length errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is false', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @view = new SisButtonView(model: @quiz, maxNameLengthRequired: false)
    @view.render()
    @view.$el.click()
    ok @quiz.postToSIS()

  test 'model does not save if there are due date errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @view = new SisButtonView(model: @assignment, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@assignment.postToSIS()

  test 'model saves if there are overrides but not base due date for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @assignment.set('all_dates', [{dueAt: 'Test'}, {dueAt: 'Test2'}])
    @assignment.set('due_at', null)
    @view = new SisButtonView(model: @assignment, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok @assignment.postToSIS()

  test 'model does not save if there are no due date overrides and no base due date for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @assignment.set('all_dates', [])
    @assignment.set('due_at', null)
    @view = new SisButtonView(model: @assignment, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@assignment.postToSIS()

  test 'model does not save if there is only one due date override and no base due date for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @assignment.set('all_dates', [{dueAt: 'Test'}, {dueAt: null}])
    @assignment.set('due_at', null)
    @view = new SisButtonView(model: @assignment, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@assignment.postToSIS()

  test 'model does not save if there are no due dates on overrides assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @assignment.set('all_dates', [{dueAt: null}, {dueAt: null}])
    @assignment.set('due_at', "I am a date")
    @view = new SisButtonView(model: @assignment, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@assignment.postToSIS()

  test 'model saves if there are overrides but not base due date for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @quiz.set('all_dates', [{dueAt: 'Test'}, {dueAt: 'Test2'}])
    @quiz.set('due_at', null)
    @view = new SisButtonView(model: @quiz, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok @quiz.postToSIS()

  test 'model does not save if there are no due date overrides and no base due date for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @quiz.set('all_dates', [])
    @quiz.set('due_at', null)
    @view = new SisButtonView(model: @quiz, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@quiz.postToSIS()

  test 'model does not save if there is only one due date override and no base due date for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @quiz.set('all_dates', [{dueAt: 'Test'}, {dueAt: null}])
    @quiz.set('due_at', null)
    @view = new SisButtonView(model: @quiz, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@quiz.postToSIS()

  test 'model saves if there are no due date overrides and base for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @quiz.set('all_dates', [{dueAt: null}, {dueAt: null}])
    @quiz.set('due_at', "I am a date")
    @view = new SisButtonView(model: @quiz, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@quiz.postToSIS()

  test 'model saves if there are due date errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is false', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    @assignment.set('post_to_sis', false)
    @assignment.set('name', 'Too Much Tuna')
    @view = new SisButtonView(model: @assignment, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok @assignment.postToSIS()

  test 'model does not save if there are due date errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @view = new SisButtonView(model: @quiz, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok !@quiz.postToSIS()

  test 'model saves if there are due date errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is false', ->
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    @quiz.set('post_to_sis', false)
    @quiz.set('title', 'Too Much Tuna')
    @view = new SisButtonView(model: @quiz, dueDateRequired: true)
    @view.render()
    @view.$el.click()
    ok @quiz.postToSIS()

  test 'does not override dates', ->
    ENV.MAX_NAME_LENGTH = 256
    @assignment.set('name', 'Gil Faizon')
    saveStub = @stub(@assignment, 'save').callsFake(() ->)
    @view = new SisButtonView(model: @assignment)
    @view.render()
    @view.$el.click()
    ok saveStub.calledWith(override_dates: false)

  test 'properly saves model with a custom url if present', ->
    ENV.MAX_NAME_LENGTH = 256
    @quiz.set('title', 'George St. Geegland')
    @stub(@quiz, 'save').callsFake (attributes, options) ->
      ok options['url'], '/some_other_url'
    @quiz.set('post_to_sis', false)
    @view = new SisButtonView(model: @quiz)
    @view.render()
    @view.$el.click()
    ok @quiz.postToSIS()

  test 'properly associates button label via aria-describedby', ->
    @assignment.set('id', '1')
    @view = new SisButtonView(model: @assignment)
    @view.render()
    equal @view.$input.attr('aria-describedby'), 'sis-status-label-1'
    equal @view.$label.attr('id'), 'sis-status-label-1'

  test 'properly toggles aria-pressed value based on post_to_sis', ->
    @assignment.set('post_to_sis', true)
    @view = new SisButtonView(model: @assignment)
    @view.render()
    equal @view.$label.attr('aria-pressed'), 'true'
    @view.$el.click()
    equal @view.$label.attr('aria-pressed'), 'false'
