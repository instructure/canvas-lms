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
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import type {CanvasSelectProps} from '@canvas/instui-bindings/react/Select'
import {useScope as useI18nScope} from '@canvas/i18n'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('edit_timezone')

type Timezone = {
  name: string
  localized_name: string
}

type Props = {
  label: string
  timezones: Timezone[]
  priority_zones: Timezone[]
  onChange: (event: React.ChangeEvent<HTMLSelectElement>, value: string) => void
} & CanvasSelectProps

const TimeZoneSelect: React.FC<Props> = ({
  label,
  timezones,
  priority_zones,
  onChange,
  ...otherPropsToPassOnToSelect
}) => {
  let idval = 0 // for setting ids on options, which are necessary for Select's inner workings but don't matter to us

  function onChangeTimezone(event: React.ChangeEvent<HTMLSelectElement>, value: string) {
    event.persist?.()
    event.target.value = value // this is how our onChange expects the result
    onChange(event, value) // so it works either way, instui Select callback, or traditional
  }
  return (
    <CanvasSelect label={label} onChange={onChangeTimezone} {...otherPropsToPassOnToSelect}>
      <CanvasSelect.Option id={`${++idval}`} value="">
        &nbsp;
      </CanvasSelect.Option>
      {[
        {label: I18n.t('Common Timezones'), timezones: priority_zones},
        {label: I18n.t('All Timezones'), timezones},
      ].map(grouping => (
        <CanvasSelect.Group key={grouping.label} label={grouping.label}>
          {grouping.timezones.map(zone => (
            <CanvasSelect.Option id={`${++idval}`} key={zone.name} value={zone.name}>
              {zone.localized_name}
            </CanvasSelect.Option>
          ))}
        </CanvasSelect.Group>
      ))}
    </CanvasSelect>
  )
}

import(
  /* webpackChunkName: "[request]" */
  `./localized-timezone-lists/${ENV.LOCALE || 'en'}.json`
)
  .catch(() => import(`./localized-timezone-lists/en.json`)) // fall back to english if a user has a locale set that we don't have a list for
  .then(defaultsJSON => {
    TimeZoneSelect.defaultProps = {
      // TODO: change ENV.LOCALE to process.env.BUILD_LOCALE once we do locale-specific builds so we only pull in that one json file
      ...defaultsJSON,
      label: I18n.t('Time Zone'),
    }
  })
  .catch(error => {
    // eslint-disable-next-line no-console
    console.error('Error loading localized timezone list', error)
    captureException(error)
  })

export default TimeZoneSelect
