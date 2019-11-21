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
import {bool, number, oneOfType, string} from 'prop-types'

export const fileShape = {
  content_type: string.isRequired,
  date: string.isRequired,
  display_name: string,
  filename: string.isRequired,
  href: string.isRequired,
  id: oneOfType([number, string]).isRequired,
  thumbnail_url: string,
  preview_url: string,
  hidden_to_user: bool,
  lock_at: string,
  unlock_at: string,
  locked_for_user: bool,
  published: bool
}
