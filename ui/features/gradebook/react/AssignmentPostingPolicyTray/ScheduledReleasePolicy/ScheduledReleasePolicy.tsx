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
import {useEffect, useState} from 'react'
import {SeparateScheduledRelease} from './SeparateScheduledRelease'
import {SharedScheduledRelease} from './SharedScheduleRelease'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('assignment_scheduled_release_policy')

export type ScheduledRelease = {
  scheduledPostMode?: string | null
  postCommentsAt?: string | null
  postGradesAt?: string | null
}

type ScheduledReleasePolicyProps = ScheduledRelease & {
  errorMessages: {grades: FormMessage[]; comments: FormMessage[]}
  handleChange: (changes: Partial<ScheduledRelease>) => void
}

export const ScheduledReleasePolicy = ({
  errorMessages,
  scheduledPostMode,
  postCommentsAt,
  postGradesAt,
  handleChange,
}: ScheduledReleasePolicyProps) => {
  const inputs = [
    {
      value: 'shared',
      label: I18n.t('Grades & Comments Together'),
      dataTestId: 'shared-scheduled-post',
    },
    {value: 'separate', label: I18n.t('Separate Schedules'), dataTestId: 'separate-scheduled-post'},
  ]

  const isScheduledRelease = !!scheduledPostMode
  const [selectedValue, setSelectedValue] = useState(scheduledPostMode)

  useEffect(() => {
    setSelectedValue(scheduledPostMode)
  }, [scheduledPostMode])

  const handleCheckboxChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    handleChange({
      scheduledPostMode: event.target.checked ? inputs[0].value : undefined,
      postCommentsAt: undefined,
      postGradesAt: undefined,
    })
  }
  const handleRadioChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSelectedValue(event.target.value)
    const postCommentsAtDate = event.target.value === 'shared' ? postGradesAt : postCommentsAt
    handleChange({
      scheduledPostMode: event.target.value,
      postCommentsAt: postCommentsAtDate,
      postGradesAt,
    })
  }
  return (
    <View as="div" margin="medium 0 0 medium" data-testid="scheduled-release-policy">
      <Checkbox
        data-testid="scheduled-release-checkbox"
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
            value={selectedValue ?? undefined}
            description={I18n.t('Release Options')}
          >
            {inputs.map(input => (
              <RadioInput
                key={input.value}
                value={input.value}
                label={input.label}
                data-testid={input.dataTestId}
              />
            ))}
          </RadioInputGroup>
          {selectedValue === 'shared' && (
            <SharedScheduledRelease
              errorMessages={errorMessages.grades}
              postGradesAt={postGradesAt}
              handleChange={(postGradesAt?: string) => {
                handleChange({postGradesAt, postCommentsAt: postGradesAt, scheduledPostMode})
              }}
            />
          )}
          {selectedValue === 'separate' && (
            <SeparateScheduledRelease
              commentErrorMessages={errorMessages.comments}
              gradeErrorMessages={errorMessages.grades}
              postCommentsAt={postCommentsAt}
              postGradesAt={postGradesAt}
              handleChange={changes => {
                handleChange({...changes, scheduledPostMode})
              }}
            />
          )}
        </View>
      )}
    </View>
  )
}
