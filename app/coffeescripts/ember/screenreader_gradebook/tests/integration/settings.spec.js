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
  '../start_app'
  'underscore'
  'ember'
  '../shared_ajax_fixtures'
  'jquery'
  'vendor/jquery.ba-tinypubsub'
], (startApp, _, Ember, fixtures, $) ->

  App = null

  QUnit.module 'global settings',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        @controller.set 'hideStudentNames', false
    teardown: ->
      Ember.run App, 'destroy'

  test 'student names are hidden', ->
    selection = '#student_select option[value=1]'
    equal $(selection).text(), "Bob"
    click("#hide_names_checkbox").then =>
      $(selection).text().search("Student") != -1
      click("#hide_names_checkbox").then =>
        equal $(selection).text(), "Bob"

  test 'secondary id says hidden', ->
    Ember.run =>
      student = @controller.get('students.firstObject')
      Ember.setProperties student,
        isLoaded: true
        isLoading: false
      @controller.set('selectedStudent', student)

    equal Ember.$.trim(find(".secondary_id").text()), ''
    click("#hide_names_checkbox")
    andThen =>
      equal $.trim(find(".secondary_id:first").text()), 'hidden'

  test 'view concluded enrollments', ->
    enrollments = @controller.get('enrollments')
    ok enrollments.content.length > 1
    _.each enrollments.content, (enrollment) ->
      ok enrollment.workflow_state == undefined

    click("#concluded_enrollments").then =>
      enrollments = @controller.get('enrollments')
      equal enrollments.content.length, 1
      en = enrollments.objectAt(0)
      ok en.workflow_state == "completed"
      completed_at = new Date(en.completed_at)
      ok completed_at.getTime() < new Date().getTime()

      click("#concluded_enrollments").then =>
        enrollments = @controller.get('enrollments')
        ok enrollments.content.length > 1
