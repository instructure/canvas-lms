/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'underscore'
import createStore from '@canvas/util/createStore'
import $ from 'jquery'

const CourseEpubExportStore = createStore({}),
  _courses = {}

CourseEpubExportStore.getAll = function() {
  $.getJSON('/api/v1/epub_exports', data => {
    _.each(data.courses, course => {
      _courses[course.id] = course
    })
    CourseEpubExportStore.setState(_courses)
  })
}

CourseEpubExportStore.get = function(course_id, id) {
  const url = '/api/v1/courses/' + course_id + '/epub_exports/' + id
  $.getJSON(url, data => {
    _courses[data.id] = data
    CourseEpubExportStore.setState(_courses)
  })
}

CourseEpubExportStore.create = function(id) {
  const url = '/api/v1/courses/' + id + '/epub_exports'
  $.post(
    url,
    {},
    data => {
      _courses[data.id] = data
      CourseEpubExportStore.setState(_courses)
    },
    'json'
  )
}

export default CourseEpubExportStore
