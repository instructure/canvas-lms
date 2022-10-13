/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {arrayOf, shape, string} from 'prop-types'

export const HistoryShape = arrayOf(
  shape({
    asset_code: string.isRequired,
    asset_name: string.isRequired,
    asset_icon: string,
    asset_readable_category: string,
    visited_url: string.isRequired,
    visited_at: string.isRequired,
    context_name: string,
  })
)
