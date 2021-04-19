/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export default {
  xhr: {
    timeout: 5000
  },

  pollingFrequency: 500,

  ajax: $.ajax,

  // This assumes you have set up reverse proxying on /api/v1 to Canvas.
  //
  // See ./README.md for more info on overriding these to use fixtures.
  quizStatisticsUrl: '/api/v1/courses/1/quizzes/1/statistics',
  quizReportsUrl: '/api/v1/courses/1/quizzes/1/reports',
  courseSectionsUrl: '/api/v1/courses/1/sections',
}
