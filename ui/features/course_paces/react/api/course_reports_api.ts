/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {
  CourseReport,
} from '../types'
import doFetchApi from '@canvas/do-fetch-api-effect'

/* API methods */

export const create = (courseReport: CourseReport) =>
  doFetchApi<CourseReport>({
    path: `/api/v1/courses/${courseReport.course_id}/reports/${courseReport.report_type}`,
    method: 'POST',
    body: courseReport,
  }).then(({json}) => json)

export const show = (courseReport: CourseReport) =>
  doFetchApi<CourseReport>({
    path: `/api/v1/courses/${courseReport.course_id}/reports/${courseReport.report_type}/${courseReport.id}`,
    fetchOpts: {cache: 'no-cache'},
  }).then(({json}) => json)

export const getLast = (courseId: string, reportType: string) =>
  doFetchApi<CourseReport>({
    path: `/api/v1/courses/${courseId}/reports/${reportType}`,
    fetchOpts: {cache: 'no-store'},
  }).then(({json}) => json)
