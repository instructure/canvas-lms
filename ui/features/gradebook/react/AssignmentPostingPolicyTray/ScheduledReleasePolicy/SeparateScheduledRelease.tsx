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
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {FormMessage} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignment_scheduled_release_policy')

export const SeparateScheduledRelease = () => {
  const [gradeReleaseDate, setGradeReleaseDate] = useState<string>()
  const [commentReleaseDate, setCommentReleaseDate] = useState<string>()
  const [messages, setMessages] = useState<FormMessage[]>([])

  const onChangeGradeReleaseDate = (_e: React.SyntheticEvent, isoDate?: string) => {
    setGradeReleaseDate(isoDate)
  }

  const onChangeCommentReleaseDate = (_e: React.SyntheticEvent, isoDate?: string) => {
    setCommentReleaseDate(isoDate)
  }

  return (
    <View as="div" margin="0 medium 0">
      <View as="div" margin="medium 0">
        <DateTimeInput
          description={<ScreenReaderContent>{I18n.t('Pick a date and time')}</ScreenReaderContent>}
          datePlaceholder={I18n.t('Select Date')}
          dateRenderLabel={I18n.t('Grades Release Date')}
          timeRenderLabel={I18n.t('Time')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          onChange={onChangeGradeReleaseDate}
          layout="stacked"
          value={gradeReleaseDate}
          invalidDateTimeMessage={I18n.t('Invalid date!')}
          messages={messages}
          allowNonStepInput={true}
          timeStep={15}
          isRequired
        />
      </View>
      <View as="div" margin="medium 0">
        <DateTimeInput
          description={<ScreenReaderContent>{I18n.t('Pick a date and time')}</ScreenReaderContent>}
          datePlaceholder={I18n.t('Select Date')}
          dateRenderLabel={I18n.t('Comments Release Date')}
          timeRenderLabel={I18n.t('Time')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          onChange={onChangeCommentReleaseDate}
          layout="stacked"
          value={commentReleaseDate}
          invalidDateTimeMessage={I18n.t('Invalid date!')}
          messages={messages}
          allowNonStepInput={true}
          timeStep={15}
          isRequired
        />
      </View>
    </View>
  )
}
