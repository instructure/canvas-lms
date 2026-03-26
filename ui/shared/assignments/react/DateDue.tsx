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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

const I18n = createI18nScope('date_due')

interface DateInfo {
  dueFor?: string
  dueAt?: string | null
}

export interface DateDueProps {
  multipleDueDates: boolean
  allDates: DateInfo[]
  singleSectionDueDate?: string | null
  todoDate?: string | null
  linkHref?: string
}

export default function DateDue({
  multipleDueDates,
  allDates,
  singleSectionDueDate,
  todoDate,
  linkHref,
}: DateDueProps) {
  const tooltipContent = () => {
    return (
      <span>
        {allDates.map((date, index) => (
          <Flex key={`${date.dueFor}_${index}`} direction="row" gap="small">
            <Text weight="bold" size="small">
              {date.dueFor}
            </Text>
            {date.dueAt ? (
              <FriendlyDatetime
                dateTime={date.dueAt}
                format={I18n.t('#date.formats.short')}
                alwaysUseSpecifiedFormat={true}
              />
            ) : (
              <Text size="small">-</Text>
            )}
          </Flex>
        ))}
      </span>
    )
  }

  if (multipleDueDates) {
    return (
      <>
        <Text weight="bold" size="x-small">
          {I18n.t('Due')}
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

  if (singleSectionDueDate) {
    return (
      <>
        <Text weight="bold" size="x-small">
          {I18n.t('Due')}
        </Text>{' '}
        <FriendlyDatetime
          dateTime={singleSectionDueDate}
          format={I18n.t('#date.formats.date_at_time')}
          alwaysUseSpecifiedFormat={true}
        />
      </>
    )
  }

  if (todoDate) {
    return (
      <>
        <Text weight="bold" size="x-small">
          {I18n.t('To do')}
        </Text>{' '}
        <FriendlyDatetime
          dateTime={todoDate}
          format={I18n.t('#date.formats.date_at_time')}
          alwaysUseSpecifiedFormat={true}
        />
      </>
    )
  }

  return null
}
