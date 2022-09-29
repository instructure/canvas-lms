/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import splitAssetString from '@canvas/util/splitAssetString'

function courseId() {
  return ENV.context_asset_string ? splitAssetString(ENV.context_asset_string)[1] : ''
}

function timezone() {
  return ENV.TIMEZONE
}

function courseIsConcluded() {
  return ENV.COURSE_IS_CONCLUDED
}

function overrideGradesEnabled() {
  return ENV.OVERRIDE_GRADES_ENABLED
}

export default {
  overrideGradesEnabled,
  courseId,
  courseIsConcluded,
  timezone,
}
