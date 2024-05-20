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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import CourseSearchFormView from './CourseSearchFormView'
import UserSearchFormView from './UserSearchFormView'
import CourseRestoreModel from '../models/CourseRestore'
import UserRestoreModel from '../models/UserRestore'
import template from '../../jst/RestoreContentPane.handlebars'

const courseRestoreModel = new CourseRestoreModel({account_id: ENV.ACCOUNT_ID})
const userRestoreModel = new UserRestoreModel({account_id: ENV.ACCOUNT_ID})

export default class RestoreContentPaneView extends Backbone.View {
  static initClass() {
    this.child('courseSearchFormView', '#courseSearchForm')
    this.child('courseSearchResultsView', '#courseSearchResults')
    this.child('userSearchFormView', '#userSearchForm')
    this.child('userSearchResultsView', '#userSearchResults')

    this.prototype.events = {'change #restoreType': 'onTypeChange'}

    this.prototype.template = template
  }

  constructor(_options) {
    super(...arguments)
    this.permissions = this.options.permissions
    this.restoreCourse = this.initCourseRestore()
    this.restoreUser = this.initUserRestore()
  }

  afterRender() {
    return this.$el.find('.restoreTypeContent').hide()
  }

  toJSON() {
    return {...this.permissions}
  }

  onTypeChange(e) {
    const $target = $(e.target)
    const value = $target.val()
    this.$el.find('.restoreTypeContent').hide()
    return this.$el.find(value).show()
  }

  initCourseRestore() {
    if (!this.permissions.restore_course) {
      return new Backbone.View()
    }

    return new CourseSearchFormView({model: courseRestoreModel})
  }

  initUserRestore() {
    if (!this.permissions.restore_user) {
      return new Backbone.View()
    }

    return new UserSearchFormView({model: userRestoreModel})
  }
}
RestoreContentPaneView.initClass()
