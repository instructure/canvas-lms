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

import React from 'react'
import {createRoot} from 'react-dom/client'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import ValidatedMixin from '@canvas/forms/backbone/views/ValidatedMixin'
import GradeChangeLoggingItemView from './GradeChangeLoggingItemView'
import GradeChangeLoggingCollection from '../collections/GradeChangeLoggingCollection'
import template from '../../jst/gradeChangeLoggingContent.handlebars'
import gradeChangeLoggingResultsTemplate from '../../jst/gradeChangeLoggingResults.handlebars'
import {extend} from '@canvas/backbone/utils'
import GradeChangeActivityForm from '../../react/GradeChangeActivityForm'

extend(GradeChangeLoggingContentView, Backbone.View)

export default function GradeChangeLoggingContentView(options) {
  this.fetch = this.fetch.bind(this)
  this.onFail = this.onFail.bind(this)
  this.options = options
  this.collection = new GradeChangeLoggingCollection()
  Backbone.View.apply(this, arguments)
  this.resultsView = new PaginatedCollectionView({
    template: gradeChangeLoggingResultsTemplate,
    itemView: GradeChangeLoggingItemView,
    collection: this.collection,
  })
}

GradeChangeLoggingContentView.mixin(ValidatedMixin)

GradeChangeLoggingContentView.child('resultsView', '#gradeChangeLoggingSearchResults')

Object.assign(GradeChangeLoggingContentView.prototype, {
  template,

  afterRender() {
    const mountPoint = document.getElementById('grade_change_activity_form_mount_point')
    const root = createRoot(mountPoint)

    root.render(
      <GradeChangeActivityForm
        accountId={ENV.ACCOUNT_ID}
        onSubmit={data => {
          this.updateCollection(data)
        }}
      />,
    )
  },

  updateCollection(json) {
    return this.collection.setParams(json)
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
            message: 'A course with that ID could not be found for this account.',
          },
        ]
      }

      if (type === 'assignments') {
        errors.assignment_id = [
          {
            type: 'required',
            message: 'An assignment with that ID could not be found for this account.',
          },
        ]
      }

      if (!$.isEmptyObject(errors)) return this.showErrors(errors)
    }
  },
})
