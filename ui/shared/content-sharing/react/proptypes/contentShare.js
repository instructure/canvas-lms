/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {oneOf, shape, string} from 'prop-types'
import displayUser from '@canvas/users/react/proptypes/user'
import contentExport from './contentExport'

export const CONTENT_SHARE_TYPES = [
  'assignment',
  'attachment',
  'discussion_topic',
  'page',
  'quiz',
  'module',
  'module_item',
]

const contentShareShape = shape({
  id: string.isRequired,
  name: string.isRequired,
  content_type: oneOf(CONTENT_SHARE_TYPES).isRequired,
  created_at: string.isRequired,
  updated_at: string.isRequired,
  read_state: string.isRequired,
  sender: displayUser,
  content_export: contentExport,
})

export default contentShareShape
