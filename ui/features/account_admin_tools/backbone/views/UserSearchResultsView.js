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

import $ from 'jquery'
import CourseSearchResultsView from './CourseSearchResultsView'
import template from '../../jst/UserSearchResults.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('user_search_results')

export default class UserSearchResultsView extends CourseSearchResultsView {
  static initClass() {
    this.prototype.template = template

    this.prototype.events = {'click #restoreUserBtn': 'restore'}

    this.prototype.els = {'#restoreUserBtn': '$restoreUserBtn'}
  }

  resultsFound() {
    if (!this.model.get('id') && this.model.get('status')) {
      return $.screenReaderFlashMessage(I18n.t('User not found'))
    } else if (this.userDeleted()) {
      return $.screenReaderFlashMessage(I18n.t('User found'))
    } else {
      return $.screenReaderFlashMessage(I18n.t('User found (not deleted)'))
    }
  }

  // Bindings are applied here to make testing a little easier.
  // @api public
  applyBindings() {
    super.applyBindings(...arguments)
    return this.model.on('doneRestoring', () => $('#viewUser').focus())
  }

  userDeleted() {
    return this.model.get('id') && this.model.get('login_id') == null
  }

  userActive() {
    return this.model.get('id') && this.model.get('login_id') != null
  }

  // Depending on what we get back when restoring the model
  // we want to display the course or error message correctly.
  toJSON(json) {
    json = super.toJSON(...arguments)
    json.showRestore = this.userDeleted()
    json.showNotFound = !this.model.get('id') && this.model.get('status')
    json.showSuccessfullRestore = this.userActive() && this.model.get('restored')
    json.showNonDeletedUser = this.userActive() && !this.model.get('restored')
    if (this.model.get('enrollments')) json.enrollmentCount = this.model.get('enrollments').length
    return json
  }
}
UserSearchResultsView.initClass()
