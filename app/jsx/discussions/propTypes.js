/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import { shape, arrayOf, string, number, bool, oneOf } from 'prop-types'

const propTypes = {}

propTypes.user = shape({
  id: string.isRequired,
  display_name: string.isRequired,
  avatar_image_url: string,
  html_url: string.isRequired,
})

propTypes.discussion = shape({
  id: string.isRequired,
  position: number.isRequired,
  published: bool.isRequired,
  title: string.isRequired,
  message: string.isRequired,
  posted_at: string.isRequired,
  author: propTypes.user.isRequired,
  read_state: oneOf(['read', 'unread']),
  unread_count: number.isRequired,
})

propTypes.discussionList = arrayOf(propTypes.discussion)

export default propTypes
