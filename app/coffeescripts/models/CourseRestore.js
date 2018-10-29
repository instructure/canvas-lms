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
import I18n from 'i18n!course_restore'
import 'jquery.instructure_forms'

export default class CourseRestore extends Backbone.Model {
  baseUrl() {
    return `/api/v1/accounts/${this.get('account_id')}/courses`
  }
  searchUrl() {
    return `${this.baseUrl()}/${this.get('id')}?include[]=all_courses`
  }

  // Search will be given an id and do an api request to populate
  // the model with the course we were searching for. The id
  // must be set for the searchUrl to work correctly.
  // @api public
  search(id) {
    this.trigger('searching')
    this.set('id', id, {silent: true})
    return this.fetch({
      url: this.searchUrl(),
      success: model => model.trigger('doneSearching'),
      error: (model, response) => {
        const account_id = this.get('account_id')
        this.clear({silent: true})
        this.set('account_id', account_id, {silent: true})
        const message = $.parseJSON(response.responseText)
        this.set(response)
        return model.trigger('doneSearching')
      }
    })
  }

  // This just cleans up data when comming back from fetch
  // before it gets slammed into the model.
  // @api backbone override private
  parse(response) {
    response.account_id = this.get('account_id') // Ensure account id stays the same
    this.clear({silent: true})
    return response
  }

  // Restore has a timeout after 60 seconds that stops the progress pulls
  // It works by creating a blank deferred object, then in this method
  // it creates a loop of ajax requests on the progress api. Once progress
  // is no longer queued (completed), it then resolves the deferred object,
  // makes sure the course is unpublished and returns the resolved deferred
  // object which then stops the loading icon.
  // @api public
  restore = () => {
    this.trigger('restoring')
    const deferred = $.Deferred()

    let takingTooLong = false
    const setTakingTooLong = () => (takingTooLong = true)
    setTimeout(setTakingTooLong, 60000)

    const ajaxRequest = (url, method = 'GET') =>
      $.ajax({
        url,
        type: method,
        success: restoreSuccess,
        error: restoreError
      })

    var restoreError = (response = {}) => {
      $.flashError(
        I18n.t(
          'restore_error',
          'There was an error attempting to restore the course. Course was not restored.'
        )
      )
      return deferred.reject()
    }

    var restoreSuccess = response => {
      if (takingTooLong) {
        return restoreError()
      }

      switch (response.workflow_state) {
        case 'queued':
        case 'running':
          return setTimeout(() => ajaxRequest(response.url), 1000) // keep sending the request if its not completed yet.
        case 'completed':
          this.set({workflow_state: 'unpublished', restored: true})
          this.trigger('doneRestoring')
          return deferred.resolve()
        case 'failed':
          return restoreError()
      }
    }

    ajaxRequest(`${this.baseUrl()}/?course_ids[]=${this.get('id')}&event=undelete`, 'PUT')
    return deferred
  }
}
