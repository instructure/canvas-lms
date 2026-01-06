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
import {useScope as createI18nScope} from '@canvas/i18n'

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
  const onChange = (_e: React.SyntheticEvent, isoDate?: string) => {
    handleChange(isoDate)
  }

  return (
    <View as="div" margin="medium medium 0" data-testid="shared-scheduled-post-datetime">
      <DateTimeInput
        description={<ScreenReaderContent>{I18n.t('Release Date')}</ScreenReaderContent>}
        datePlaceholder={I18n.t('Choose release date')}
        dateRenderLabel={I18n.t('Release Date')}
        timeRenderLabel={I18n.t('Time')}
        prevMonthLabel={I18n.t('Previous month')}
        nextMonthLabel={I18n.t('Next month')}
        onChange={onChange}
        layout="stacked"
        value={postGradesAt ?? undefined}
        invalidDateTimeMessage={I18n.t('Invalid date!')}
        messages={errorMessages}
        allowNonStepInput={true}
        timeStep={15}
        isRequired
      />
    </View>
  )
}
