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

import {shape, bool, string, number} from 'prop-types'

const propTypes = {}

propTypes.permissions = shape({
  create: bool.isRequired,
  manage_course_content_edit: bool.isRequired,
  manage_course_content_delete: bool.isRequired,
  moderate: bool.isRequired,
})

propTypes.rssFeed = shape({
  id: string.isRequired,
  display_name: string.isRequired,
  external_feed_entries_count: number.isRequired,
  url: string.isRequired,
})

export default propTypes
