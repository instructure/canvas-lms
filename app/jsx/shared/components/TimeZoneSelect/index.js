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

import React from 'react'
import {arrayOf, shape, string} from 'prop-types'
import Select from '@instructure/ui-core/lib/components/Select'
import I18n from 'i18n!edit_timezone'

export default function TimeZoneSelect({label, timezones, priority_zones, ...otherPropsToPassOnToSelect}) {
  return (
    <Select {...otherPropsToPassOnToSelect} label={label} >
      <option value="" />
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
    </Select>
  )
}

const timezoneShape = shape({
  name: string.isRequired,
  localized_name: string.isRequired
}).isRequired

TimeZoneSelect.propTypes = {
  ...Select.propTypes, // this accepts any prop you'd pass to InstUI's Select. see it's docs for examples
  timezones: arrayOf(timezoneShape),
  priority_zones: arrayOf(timezoneShape)
}

TimeZoneSelect.defaultProps = {
  // TODO: change ENV.LOCALE to process.env.BUILD_LOCALE once we do locale-specific builds so we only pull in that one json file
  ...require(`./localized-timezone-lists/${ENV.LOCALE || 'en'}.json`),
  label: I18n.t('Time Zone')
}
