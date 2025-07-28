/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import {firstNameFirst, lastNameFirst, nameParts} from '../jquery/user_utils'

export const computeShortAndSortableNamesFromName = (names: {
  prior_name: string
  name: string
  short_name: string
  sortable_name: string
}) => {
  const sortable_name_parts = nameParts(names.sortable_name)

  if (
    $.trim(names.sortable_name) === '' ||
    firstNameFirst(sortable_name_parts) === $.trim(names.prior_name)
  ) {
    const parts = nameParts(names.name, sortable_name_parts[1])
    names.sortable_name = lastNameFirst(parts)
  }

  if ($.trim(names.short_name) === '' || names.short_name === names.prior_name) {
    names.short_name = names.name
  }

  return names
}
