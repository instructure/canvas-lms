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

import {arrayOf, exact, number, oneOfType, string} from 'prop-types'

const CONTENT_SELECTION_TYPES = [
  'folders',
  'files',
  'attachments',
  'quizzes',
  'assignments',
  'announcements',
  'calendar_events',
  'discussion_topics',
  'modules',
  'module_items',
  'pages',
  'rubrics',
]

// build the shape {folders: arrayOf(...), files: arrayOf(...), ...}
const contentSelectionShape = exact(
  CONTENT_SELECTION_TYPES.reduce((selections, type) => {
    selections[type] = arrayOf(oneOfType([string, number]))
    return selections
  }, {})
)

export default contentSelectionShape
