/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!student_groups'
import React from 'react'

export default function Filter(props) {
  return (
    <div className="form-inline clearfix content-box">
      <input
        id="search_field"
        placeholder={I18n.t('Search Groups or People')}
        type="search"
        onChange={props.onChange}
        aria-label={I18n.t(
          'As you type in this field, the list of groups will be automatically filtered to only include those whose names match your input.'
        )}
      />
    </div>
  )
}
