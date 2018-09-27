//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'Backbone'
import $ from 'jquery'
import AuthLoggingContentPaneView from './AuthLoggingContentPaneView'
import GradeChangeLoggingContentView from './GradeChangeLoggingContentView'
import CourseLoggingContentView from './CourseLoggingContentView'
import template from 'jst/accounts/admin_tools/loggingContentPane'

export default class LoggingContentPaneView extends Backbone.View {
  static initClass() {
    this.child('authentication', '#loggingAuthentication')
    this.child('gradeChange', '#loggingGradeChange')
    this.child('course', '#loggingCourse')

    this.prototype.events = {'change #loggingType': 'onTypeChange'}

    this.prototype.template = template
  }

  constructor(options) {
    super(...arguments)
    this.permissions = this.options.permissions
    this.authentication = this.initAuthLogging()
    this.gradeChange = this.initGradeChangeLogging()
    this.course = this.initCourseLogging()
  }

  afterRender() {
    return this.$el.find('.loggingTypeContent').hide()
  }

  toJSON() {
    return this.permissions
  }

  onTypeChange(e) {
    const $target = $(e.target)
    const value = $target.val()
    this.$el.find('.loggingTypeContent').hide()
    return this.$el.find(value).show()
  }

  initAuthLogging() {
    if (!this.permissions.authentication) {
      return new Backbone.View()
    }

    return new AuthLoggingContentPaneView({
      users: this.options.users
    })
  }

  initGradeChangeLogging() {
    if (!this.permissions.grade_change) {
      return new Backbone.View()
    }

    return new GradeChangeLoggingContentView({
      users: this.options.users
    })
  }

  initCourseLogging() {
    if (!this.permissions.course) {
      return new Backbone.View()
    }

    return new CourseLoggingContentView()
  }
}
LoggingContentPaneView.initClass()
