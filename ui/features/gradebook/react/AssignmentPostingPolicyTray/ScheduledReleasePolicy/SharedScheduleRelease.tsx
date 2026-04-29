/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {FormFieldGroup, FormMessage} from '@instructure/ui-form-field'
import {TimeSelect} from '@instructure/ui-time-select'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {combineDateTime} from './utils/utils'

const I18n = createI18nScope('assignment_scheduled_release_policy')

type SharedScheduledReleaseProps = {
  errorMessages: FormMessage[]
  postGradesAt?: string | null
  handleChange: (value?: string) => void
}

export const SharedScheduledRelease = ({
  errorMessages,
  postGradesAt,
  handleChange,
}: SharedScheduledReleaseProps) => {
  const onDateChange = (date: Date | null) => {
    const newDateTime = combineDateTime(date?.toISOString(), postGradesAt)
    handleChange(newDateTime)
  }

  const onTimeChange = (_e: React.SyntheticEvent, data: {value: string; inputText: string}) => {
    const newDateTime = combineDateTime(postGradesAt, data.value)
    handleChange(newDateTime)
  }

  const dateFormatter = useDateTimeFormat('date.formats.compact')

  return (
    <View as="div" margin="medium medium 0" data-testid="shared-scheduled-post-datetime">
      <FormFieldGroup
        description={<ScreenReaderContent>{I18n.t('Release Date and Time')}</ScreenReaderContent>}
        layout="stacked"
      >
        <CanvasDateInput2
          renderLabel={I18n.t('Release Date')}
          screenReaderLabels={{
            calendarIcon: I18n.t('Calendar'),
            nextMonthButton: I18n.t('Next month'),
            prevMonthButton: I18n.t('Previous month'),
          }}
          placeholder={I18n.t('Choose release date')}
          selectedDate={postGradesAt}
          formatDate={dateFormatter}
          onSelectedDateChange={onDateChange}
          interaction="enabled"
          invalidDateMessage={I18n.t('Invalid date')}
          isRequired
          messages={errorMessages}
        />
        <TimeSelect
          width="100%"
          renderLabel={I18n.t('Release Time')}
          placeholder={I18n.t('Choose release time')}
          value={postGradesAt ?? undefined}
          step={15}
          format="LT"
          isRequired
          onChange={onTimeChange}
        />
      </FormFieldGroup>
    </View>
  )
}
