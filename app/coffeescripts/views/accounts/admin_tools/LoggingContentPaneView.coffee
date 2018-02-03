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
  'Backbone'
  'jquery'
  './AuthLoggingContentPaneView'
  './GradeChangeLoggingContentView'
  './CourseLoggingContentView'
  'jst/accounts/admin_tools/loggingContentPane'
], (
  Backbone,
  $,
  AuthLoggingContentPaneView,
  GradeChangeLoggingContentView,
  CourseLoggingContentView,
  template
) ->
  class LoggingContentPaneView extends Backbone.View
    @child 'authentication', '#loggingAuthentication'
    @child 'gradeChange', '#loggingGradeChange'
    @child 'course', '#loggingCourse'

    events:
      'change #loggingType': 'onTypeChange'

    template: template

    constructor: (@options) ->
      super
      @permissions = @options.permissions
      @authentication = @initAuthLogging()
      @gradeChange = @initGradeChangeLogging()
      @course = @initCourseLogging()

    afterRender: ->
      @$el.find(".loggingTypeContent").hide()

    toJSON: ->
      @permissions

    onTypeChange: (e) ->
      $target = $(e.target)
      value = $target.val()
      @$el.find(".loggingTypeContent").hide()
      @$el.find(value).show()

    initAuthLogging: ->
      unless @permissions.authentication
        return new Backbone.View

      return new AuthLoggingContentPaneView
        users: @options.users

    initGradeChangeLogging: ->
      unless @permissions.grade_change
        return new Backbone.View

      return new GradeChangeLoggingContentView
        users: @options.users

    initCourseLogging: ->
      unless @permissions.course
        return new Backbone.View

      return new CourseLoggingContentView
