/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import type {APIPaceContextTypes, PaceContext, PaceContextTypes} from '../types'

export const generateModalLauncherId = (paceContext: PaceContext) =>
  `pace-modal-launcher-${paceContext.type}-${paceContext.item_id}`

export const API_CONTEXT_TYPE_MAP: {[k in APIPaceContextTypes]: PaceContextTypes} = {
  course: 'Course',
  section: 'Section',
  student_enrollment: 'Enrollment',
}

export const CONTEXT_TYPE_MAP: {[k: string]: PaceContextTypes} = {
  Course: 'Course',
  CourseSection: 'Section',
  StudentEnrollment: 'Enrollment',
}
