/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import PageViewCollection from 'compiled/collections/PageViewCollection'
import PageViewView from 'compiled/views/contexts/PageViewView'
import ready from '@instructure/ready'

ready(() => {
  const $container = $('#pageviews')
  const $table = $container.find('table')
  const userId = $table.attr('data-user-id')

  const pageViews = new PageViewCollection()
  pageViews.url = `/api/v1/users/${userId}/page_views`

  const fetchOptions = {reset: true}

  const pageViewsView = new PageViewView({
    collection: pageViews,
    el: $table,
    fetchOptions
  })

  // Add events
  pageViews.on('reset', pageViewsView.render, pageViewsView)

  // Fetch page views
  const fetchParams = {per_page: 100}
  pageViewsView.$el.disableWhileLoading(pageViews.fetch({data: fetchParams}))
})
