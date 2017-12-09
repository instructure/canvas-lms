/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import {arrayOf, shape, string} from 'prop-types'
import I18n from 'i18n!edit_timezone'

export default function TimeZoneSelect({timezones, priority_zones}) {
  return (
    <select>
      {[
        {label: I18n.t('Common Timezones'), timezones: priority_zones},
        {label: I18n.t('All Timezones'), timezones}
      ].map(({label, timezones}) => (
        <optgroup key={label} label={label}>
          {timezones.map(zone => (
            <option key={zone.name} value={zone.name}>
              {zone.localized_name}
            </option>
          ))}
        </optgroup>
      ))}
    </select>
  )
}

const timezoneShape = shape({
  name: string.isRequired,
  localized_name: string.isRequired
}).isRequired

TimeZoneSelect.propTypes = {
  timezones: arrayOf(timezoneShape).isRequired,
  priority_zones: arrayOf(timezoneShape).isRequired
}
