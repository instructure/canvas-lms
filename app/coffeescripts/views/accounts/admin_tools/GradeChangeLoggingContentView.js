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
import PaginatedCollectionView from '../../PaginatedCollectionView'
import DateRangeSearchView from './DateRangeSearchView'
import AutocompleteView from './AutocompleteView'
import ValidatedMixin from '../../ValidatedMixin'
import GradeChangeLoggingItemView from './GradeChangeLoggingItemView'
import GradeChangeLoggingCollection from '../../../collections/GradeChangeLoggingCollection'
import template from 'jst/accounts/admin_tools/gradeChangeLoggingContent'
import gradeChangeLoggingResultsTemplate from 'jst/accounts/admin_tools/gradeChangeLoggingResults'
import _inherits from '@babel/runtime/helpers/esm/inheritsLoose'

_inherits(GradeChangeLoggingContentView, Backbone.View)

export default function GradeChangeLoggingContentView(options) {
  this.fetch = this.fetch.bind(this)
  this.onFail = this.onFail.bind(this)
  this.options = options
  this.collection = new GradeChangeLoggingCollection()
  Backbone.View.apply(this, arguments)
  this.dateRangeSearch = new DateRangeSearchView({
    name: 'gradeChangeLogging'
  })
  this.graderSearch = new AutocompleteView({
    collection: this.options.users,
    fieldName: 'grader_id',
    placeholder: 'Grader'
  })
  this.studentSearch = new AutocompleteView({
    collection: this.options.users,
    fieldName: 'student_id',
    placeholder: 'Student'
  })
  this.resultsView = new PaginatedCollectionView({
    template: gradeChangeLoggingResultsTemplate,
    itemView: GradeChangeLoggingItemView,
    collection: this.collection
  })
}

GradeChangeLoggingContentView.mixin(ValidatedMixin)

GradeChangeLoggingContentView.child('resultsView', '#gradeChangeLoggingSearchResults')
GradeChangeLoggingContentView.child('dateRangeSearch', '#gradeChangeDateRangeSearch')
GradeChangeLoggingContentView.child('graderSearch', '#gradeChangeGraderSearch')
GradeChangeLoggingContentView.child('studentSearch', '#gradeChangeStudentSearch')

Object.assign(GradeChangeLoggingContentView.prototype, {
  els: {
    '#gradeChangeLoggingSearch': '$gradeChangeLogginSearch',
    '#gradeChangeLoggingForm': '$form'
  },

  template,

  events: {'submit #gradeChangeLoggingForm': 'onSubmit'},

  onSubmit(event) {
    event.preventDefault()
    const json = this.$form.toJSON()
    if (this.validate(json)) {
      return this.updateCollection(json)
    }
  },

  updateCollection(json) {
    // Update the params (which fetches the collection)
    if (!json) json = this.$form.toJSON()

    // TODO remove this check after OSS instances have been given a path to migrate from cassandra auditors
    if (ENV.enhanced_grade_change_query) {
      return this.collection.setParams(json)
    } else {
      const params = {
        id: null,
        type: null,
        start_time: '',
        end_time: ''
      }

      if (json.start_time) params.start_time = json.start_time
      if (json.end_time) params.end_time = json.end_time

      if (json.grader_id) {
        params.type = 'graders'
        params.id = json.grader_id
      }

      if (json.student_id) {
        params.type = 'students'
        params.id = json.student_id
      }

      if (json.course_id) {
        params.type = 'courses'
        params.id = json.course_id
      }

      if (json.assignment_id) {
        params.type = 'assignments'
        params.id = json.assignment_id
      }

      return this.collection.setParams(params)
    }
  },

  validate(json) {
    if (!json) {
      json = this.$form.toJSON()
    }
    delete json.gradeChange_submit
    const errors = this.dateRangeSearch.validate(json) || {}
    if (!json.course_id && !json.student_id && !json.grader_id && !json.assignment_id) {
      errors.gradeChange_submit = [
        {
          type: 'required',
          message:
            'A valid Grader, Student, Course Id, or Assignment Id is required to search events.'
        }
      ]
    }
    this.showErrors(errors)
    return $.isEmptyObject(errors)
  },

  attach() {
    return this.collection.on('setParams', this.fetch)
  },

  fetch() {
    return this.collection.fetch({error: this.onFail})
  },

  onFail(collection, xhr) {
    // Received a 404, empty the collection and don't let the paginated
    // view try to fetch more.

    this.collection.reset()
    this.resultsView.detachScroll()
    this.resultsView.$el.find('.paginatedLoadingIndicator').fadeOut()

    if ((xhr != null ? xhr.status : undefined) != null && xhr.status === 404) {
      const {type} = this.collection.options.params
      const errors = {}

      if (type === 'courses') {
        errors.course_id = [
          {
            type: 'required',
            message: 'A course with that ID could not be found for this account.'
          }
        ]
      }

      if (type === 'assignments') {
        errors.assignment_id = [
          {
            type: 'required',
            message: 'An assignment with that ID could not be found for this account.'
          }
        ]
      }

      if (!$.isEmptyObject(errors)) return this.showErrors(errors)
    }
  }
})
