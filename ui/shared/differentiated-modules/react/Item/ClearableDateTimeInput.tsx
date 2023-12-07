/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import type {InferType} from 'prop-types'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints/'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface ClearableDateTimeInputProps {
  description: string
  dateRenderLabel: string
  value: string | null
  messages: Array<{type: 'error'; text: string}>
  onChange: (event: React.SyntheticEvent, value: string | undefined) => void
  onClear: () => void
  breakpoints: InferType<typeof breakpointsShape>
}

function ClearableDateTimeInput({
  description,
  dateRenderLabel,
  value,
  messages,
  onChange,
  onClear,
  breakpoints,
}: ClearableDateTimeInputProps) {
  const determineHeight = () => {
    if (breakpoints?.mobileOnly) {
      return 'auto'
    } else if (messages.length > 0) {
      return '134px'
    } else {
      return '97px'
    }
  }

  return (
    <Flex
      as="div"
      margin="small none"
      height={determineHeight()}
      direction={breakpoints?.mobileOnly ? 'column' : 'row'}
      alignItems={breakpoints?.mobileOnly ? undefined : 'center'}
    >
      <Flex.Item
        shouldShrink={true}
        overflowX="visible"
        overflowY="visible"
        align={breakpoints?.mobileOnly ? undefined : 'start'}
      >
        <DateTimeInput
          allowNonStepInput={true}
          colSpacing="small"
          dateFormat="MMM D, YYYY"
          description={<ScreenReaderContent>{description}</ScreenReaderContent>}
          dateRenderLabel={dateRenderLabel}
          timeRenderLabel={I18n.t('Time')}
          invalidDateTimeMessage={I18n.t('Invalid date')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          value={value ?? undefined}
          layout="columns"
          messages={messages}
          onChange={onChange}
        />
      </Flex.Item>
      <Flex.Item overflowX="visible" overflowY="visible">
        <CondensedButton
          onClick={onClear}
          margin={breakpoints?.mobileOnly ? 'small 0 0 0' : '0 0 0 small'}
        >
          {I18n.t('Clear')}
        </CondensedButton>
      </Flex.Item>
    </Flex>
  )
}

export default WithBreakpoints(ClearableDateTimeInput)
