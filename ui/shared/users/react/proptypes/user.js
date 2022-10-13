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

import {shape, string} from 'prop-types'

// corresponds to user_display_json in the Ruby json serializers
const displayUser = shape({
  id: string.isRequired,
  display_name: string.isRequired,
  avatar_image_url: string,
})
export default displayUser

// corresponds to user_json in the Ruby json serializers
export const basicUser = shape({
  id: string.isRequired,
  name: string.isRequired,
  avatar_url: string,
  email: string,
})

// we might add more comprehensive user shapes in the future
export const author = shape({
  id: string.isRequired,
  name: string.isRequired,
  avatar_image_url: string,
  html_url: string.isRequired,
})
