//
// Copyright (C) 2014 - present Instructure, Inc.
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
import CourseLoggingItemView from './CourseLoggingItemView'
import CourseLoggingCollection from '../collections/CourseLoggingCollection'
import template from '../../jst/courseLoggingContent.handlebars'
import courseLoggingResultsTemplate from '../../jst/courseLoggingResults.handlebars'
import {extend} from '@canvas/backbone/utils'
import CourseActivityDetails from '../../react/CourseActivityDetails'
import CourseActivityForm from '../../react/CourseActivityForm'

extend(CourseLoggingContentView, Backbone.View)

export default function CourseLoggingContentView(options) {
  this.fetch = this.fetch.bind(this)
  this.onFail = this.onFail.bind(this)
  this.options = options
  this.collection = new CourseLoggingCollection()
  Backbone.View.apply(this, arguments)
  this.resultsView = new PaginatedCollectionView({
    template: courseLoggingResultsTemplate,
    itemView: CourseLoggingItemView,
    collection: this.collection,
  })
}
CourseLoggingContentView.mixin(ValidatedMixin)
CourseLoggingContentView.child('resultsView', '#courseLoggingSearchResults')

Object.assign(CourseLoggingContentView.prototype, {
  template,

  events: {
    'click #courseLoggingSearchResults .courseLoggingDetails > a': 'showDetails',
  },

  afterRender() {
    const mountPoint = document.getElementById('course_activity_form_mount_point')
    const root = createRoot(mountPoint)

    root.render(
      <CourseActivityForm
        accountId={ENV.ACCOUNT_ID}
        onSubmit={data => {
          this.updateCollection(data)
        }}
      />,
    )
  },

  showDetails(event) {
    event.preventDefault()
    const $target = $(event.target)
    const id = $target.data('id')

    const model = this.collection.get(id)
    if (model === null || typeof model === 'undefined') {
      console.warn(`Could not find model for event ${id}.`)
      return
    }

    const type = model.get('event_type')
    if (type === null || typeof type === 'undefined') {
      console.warn(`Could not find type for event ${id}.`)
      return
    }

    const mountPoint = document.getElementById('course_activity_details_mount_point')
    const root = createRoot(mountPoint)

    root.render(<CourseActivityDetails {...model.present()} onClose={() => root.unmount()} />)
  },

  updateCollection(json) {
    const params = {
      id: null,
      type: null,
      start_time: '',
      end_time: '',
    }

    if (json.start_time) params.start_time = json.start_time
    if (json.end_time) params.end_time = json.end_time

    if (json.course_id) params.id = json.course_id

    return this.collection.setParams(params)
  },

  attach() {
    return this.collection.on('setParams', this.fetch)
  },

  fetch() {
    return this.collection.fetch({error: this.onFail})
  },

  onFail(_collection, xhr) {
    // Received a 404, empty the collection and don't let the paginated
    // view try to fetch more.
    this.collection.reset()
    this.resultsView.detachScroll()
    this.resultsView.$el.find('.paginatedLoadingIndicator').fadeOut()

    if ((xhr != null ? xhr.status : undefined) != null && xhr.status === 404) {
      const errors = {}
      errors.course_id = [
        {
          type: 'required',
          message: 'A course with that ID could not be found for this account.',
        },
      ]
      if (!$.isEmptyObject(errors)) return this.showErrors(errors)
    }
  },
})
