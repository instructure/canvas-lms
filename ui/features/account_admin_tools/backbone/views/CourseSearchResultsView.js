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
import template from '../../jst/CourseSearchResults.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('course_search_results')

export default class CourseSearchResultsView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.events = {'click #restoreCourseBtn': 'restore'}

    this.prototype.els = {'#restoreCourseBtn': '$restoreCourseBtn'}
  }

  initialize(_options) {
    this.disableResults = this.disableResults.bind(this)
    this.resultsFound = this.resultsFound.bind(this)
    super.initialize(...arguments)
    return this.applyBindings()
  }

  // Disable the search results. This means you cannot
  // restore a course when a search is happening.
  disableResults() {
    return this.$el.find('button').prop('disabled', true)
  }

  resultsFound() {
    if (!this.model.get('id') && this.model.get('status')) {
      return $.screenReaderFlashMessage(I18n.t('Course not found'))
    } else if (this.model.get('workflow_state') === 'deleted') {
      return $.screenReaderFlashMessage(I18n.t('Course found'))
    } else {
      return $.screenReaderFlashMessage(I18n.t('Course found (not deleted)'))
    }
  }

  // Bindings are applied here to make testing a little easier.
  // @api public
  applyBindings() {
    this.model.on('doneSearching', this.resultsFound, this)
    this.model.on('change', this.render, this)
    this.model.on('searching', () => {
      this.model.set('restored', false)
      return this.disableResults()
    })
    return this.model.on('doneRestoring', () => $('#viewCourse').focus())
  }

  // Restore just calls @model.restore and waits for the
  // deferred object to finish.
  // @api private
  restore(event) {
    event.preventDefault()

    const dfd = this.model.restore()
    return this.$el.disableWhileLoading(dfd)
  }

  // Depending on what we get back when restoring the model
  // we want to display the course or error message correctly.
  toJSON(json) {
    json = super.toJSON(...arguments)
    json.showRestore = this.model.get('id') && this.model.get('workflow_state') === 'deleted'
    json.showNotFound = !this.model.get('id') && this.model.get('status')
    json.showSuccessfullRestore =
      this.model.get('id') &&
      this.model.get('workflow_state') !== 'deleted' &&
      this.model.get('restored')
    json.showNonDeletedCourse =
      this.model.get('id') &&
      this.model.get('workflow_state') !== 'deleted' &&
      !this.model.get('restored')
    if (this.model.get('enrollments')) json.enrollmentCount = this.model.get('enrollments').length
    return json
  }
}
CourseSearchResultsView.initClass()
