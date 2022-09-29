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

import {shape, arrayOf, string, number, bool, oneOf} from 'prop-types'
import {author} from '@canvas/users/react/proptypes/user'

const announcement = shape({
  id: string.isRequired,
  position: number.isRequired,
  published: bool.isRequired,
  title: string.isRequired,
  message: string.isRequired,
  posted_at: string,
  delayed_post_at: string,
  author: author.isRequired,
  read_state: oneOf(['read', 'unread']),
  discussion_subentry_count: number.isRequired,
  unread_count: number.isRequired,
  locked: bool.isRequired,
  html_url: string.isRequired,
})

export const announcementList = arrayOf(announcement)

export default announcement
