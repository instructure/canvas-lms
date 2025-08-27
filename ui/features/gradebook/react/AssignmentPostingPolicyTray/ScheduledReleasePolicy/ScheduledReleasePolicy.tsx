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

import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {useState} from 'react'
import {SeparateScheduledRelease} from './SeparateScheduledRelease'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SharedScheduledRelease} from './SharedScheduleRelease'

const I18n = createI18nScope('assignment_scheduled_release_policy')

export const ScheduledReleasePolicy = () => {
  const inputs = [
    {value: 'shared', label: I18n.t('Grades & Comments Together')},
    {value: 'separate', label: I18n.t('Separate Schedules')},
  ]

  const [isScheduledRelease, setIsScheduledRelease] = useState<boolean>(false)
  const [selectedValue, setSelectedValue] = useState<string>('shared')

  const handleCheckboxChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setIsScheduledRelease(event.target.checked)
  }
  const handleRadioChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSelectedValue(event.target.value)
  }
  return (
    <View as="div" margin="medium 0 0 medium">
      <Checkbox
        label={I18n.t('Schedule Release Dates')}
        value="scheduled_release"
        checked={isScheduledRelease}
        onChange={handleCheckboxChange}
      />
      {isScheduledRelease && (
        <View as="div" margin="medium 0">
          <RadioInputGroup
            onChange={handleRadioChange}
            name="scheduled_release_policy"
            value={selectedValue}
            description={
              <ScreenReaderContent>
                {I18n.t(
                  'When the assignment is released, grades and comments will be posted together or separately.',
                )}
              </ScreenReaderContent>
            }
          >
            {inputs.map(input => (
              <RadioInput key={input.value} value={input.value} label={input.label} />
            ))}
          </RadioInputGroup>
          {selectedValue === 'shared' && <SharedScheduledRelease />}
          {selectedValue === 'separate' && <SeparateScheduledRelease />}
        </View>
      )}
    </View>
  )
}
