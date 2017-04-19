#
# Copyright (C) 2017 - present Instructure, Inc.
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
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/Course'
  'compiled/models/AssignmentGroup'
  'compiled/views/assignments/AssignmentSyncSettingsView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, AssignmentGroupCollection, Course, AssignmentGroup,
    AssignmentSyncSettingsView, $, fakeENV) ->

  group = (opts = {}) ->
    new AssignmentGroup $.extend({group_weight: 50}, opts)

  assignmentGroups = ->
    @groups = new AssignmentGroupCollection([group(), group()])

  createView = (opts = {}) ->
    @course = new Course
    @course.urlRoot = "/courses/1"
    view = new AssignmentSyncSettingsView
      model: @course
      userIsAdmin: false
    view.open()
    view

  QUnit.module 'AssignmentSyncSettingsView',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  # Add specs when backend is wired up
