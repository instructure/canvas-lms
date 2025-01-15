/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import ClearableDateTimeInput from '@canvas/context-modules/differentiated-modules/react/Item/ClearableDateTimeInput'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints/'

const I18n = createI18nScope('groups')

type SelfSignupEndDateProps = {
  initialEndDate?: string
  onDateChange: (date: string | undefined) => void
  breakpoints: Breakpoints
}

const SelfSignupEndDate = ({initialEndDate, onDateChange, breakpoints}: SelfSignupEndDateProps) => {
  const [endDate, setEndDate] = useState(initialEndDate)

  const handleEndDateUpdate = (_event: React.SyntheticEvent, value: string | undefined) => {
    setEndDate(value)
    onDateChange(value)
  }

  return (
    <View data-testid="self-signup-end-date">
      <ClearableDateTimeInput
        dateRenderLabel={I18n.t('Self Sign-up Deadline')}
        clearButtonAltLabel={I18n.t('Clear Self Sign-up Deadline')}
        description={I18n.t('Choose a self sign-up deadline date and time')}
        value={endDate || null}
        onChange={handleEndDateUpdate}
        onClear={() => setEndDate('')}
        messages={[]}
        breakpoints={breakpoints}
      />
    </View>
  )
}

export default WithBreakpoints(SelfSignupEndDate)
