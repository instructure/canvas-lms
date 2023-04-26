/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import ready from '@instructure/ready'
import UserCollection from '@canvas/users/backbone/collections/UserCollection'
import progressionsIndexTemplate from './jst/ProgressionsIndex.handlebars'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import ProgressionStudentView from './backbone/views/ProgressionStudentView'

ready(() => {
  let students
  $(document.body).addClass('context_modules2')

  if (ENV.RESTRICTED_LIST) {
    students = new UserCollection(ENV.VISIBLE_STUDENTS)
    students.urls = null
  } else {
    students = new UserCollection(null, {
      params: {
        per_page: 50,
        enrollment_type: 'student',
      },
    })
  }

  const indexView = new PaginatedCollectionView({
    collection: students,
    itemView: ProgressionStudentView,
    template: progressionsIndexTemplate,
    modules_url: ENV.MODULES_URL,
    autoFetch: true,
  })

  if (!ENV.RESTRICTED_LIST) {
    // attach the view's scroll container once it's populated
    students.fetch({
      success() {
        if (students.length === 0) return
        indexView.resetScrollContainer(
          indexView.$el.find('#progression_students .collectionViewItems')
        )
      },
    })
  }

  indexView.render()
  if (ENV.RESTRICTED_LIST && ENV.VISIBLE_STUDENTS.length === 1) {
    indexView.$el.find('#progression_students').hide()
  }
  indexView.$el.appendTo($('#content'))
})
