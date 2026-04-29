/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {ComponentProps} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

const I18n = createI18nScope('date_available')

interface DateInfo {
  dueFor?: string
  unlockAt?: string | null
  lockAt?: string | null
  pending?: boolean
  open?: boolean
  closed?: boolean
  available?: boolean
}

export interface DateAvailableProps {
  multipleDueDates: boolean
  allDates: DateInfo[]
  defaultDates: DateInfo
  linkHref?: string
}

function AvailabilityDescription({
  date,
  fontSize,
}: {
  date: DateInfo
  fontSize?: ComponentProps<typeof Text>['size']
}) {
  if (date.pending && date.unlockAt) {
    return (
      <>
        <Text weight="bold" size={fontSize}>
          {I18n.t('Not available until')}
        </Text>{' '}
        <FriendlyDatetime
          dateTime={date.unlockAt}
          format={I18n.t('#date.formats.date_at_time')}
          alwaysUseSpecifiedFormat={true}
        />
      </>
    )
  }

  if (date.open && date.lockAt) {
    return (
      <>
        <Text weight="bold" size={fontSize}>
          {I18n.t('Available until')}
        </Text>{' '}
        <FriendlyDatetime
          dateTime={date.lockAt}
          format={I18n.t('#date.formats.date_at_time')}
          alwaysUseSpecifiedFormat={true}
        />
      </>
    )
  }

  if (date.closed) {
    return (
      <Text weight="bold" size={fontSize}>
        {I18n.t('Closed')}
      </Text>
    )
  }

  if (date.available) {
    return <Text size={fontSize}>{I18n.t('Available')}</Text>
  }

  return null
}

export default function DateAvailable({
  multipleDueDates,
  allDates,
  defaultDates,
  linkHref,
}: DateAvailableProps) {
  const tooltipContent = () => {
    return (
      <span>
        {allDates.map((date, index) => (
          <Flex key={`${date.dueFor}_${index}`} direction="row" gap="small">
            <Text weight="bold" size="small">
              {date.dueFor}
            </Text>
            <AvailabilityDescription date={date} fontSize="small" />
          </Flex>
        ))}
      </span>
    )
  }

  if (multipleDueDates) {
    return (
      <>
        <Text weight="bold" size="x-small">
          {I18n.t('Available')}
        </Text>{' '}
        {allDates.length > 0 ? (
          <Tooltip renderTip={tooltipContent} on={['hover', 'focus']}>
            <Link href={linkHref} isWithinText={false}>
              {I18n.t('Multiple Dates')}
            </Link>
          </Tooltip>
        ) : (
          I18n.t('Multiple Dates')
        )}
      </>
    )
  }

  return (
    <span className="default-dates">
      <AvailabilityDescription date={defaultDates} fontSize="x-small" />
    </span>
  )
}
