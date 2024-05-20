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
import classnames from 'classnames'
import type {GradeStatusUnderscore} from '@canvas/grading/accountGradingStatus'
import {useScope as useI18nScope} from '@canvas/i18n'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {RadioInput} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('gradebook')

export type PendingUpdateData = {
  customGradeStatusId?: string
}

export type SubmissionTrayRadioInputGroupProps = {
  customGradeStatuses?: GradeStatusUnderscore[]
  disabled: boolean
  hasOverrideScore?: boolean
  selectedCustomStatusId?: string | null
  handleRadioInputChanged: (status: string | null) => void
}

type RadioInputOption = {
  checked: boolean
  color?: string
  key: string
  name: string
  disabled?: boolean
}

export default function GradeOverrideTrayRadioInputGroup({
  disabled,
  hasOverrideScore,
  customGradeStatuses = [],
  selectedCustomStatusId,
  handleRadioInputChanged,
}: SubmissionTrayRadioInputGroupProps) {
  const radioInputOptions = (): RadioInputOption[] => {
    const noneOption: RadioInputOption = {
      name: I18n.t('None'),
      checked: !selectedCustomStatusId,
      key: 'none',
    }
    const customGradingStatusOptions: RadioInputOption[] = customGradeStatuses.map(status => ({
      name: status.name,
      checked: selectedCustomStatusId === status.id,
      color: status.color,
      key: status.id,
      disabled: status.allow_final_grade_value === false && hasOverrideScore,
    }))

    return [noneOption, ...customGradingStatusOptions]
  }

  const getRadioInputClasses = (color: string) => {
    return classnames('SubmissionTray__RadioInput', {
      'SubmissionTray__RadioInput-WithBackground': color !== 'transparent',
    })
  }

  const onRadioInputChanged = (event: React.ChangeEvent<HTMLInputElement>) => {
    const {
      target: {value},
    } = event

    handleRadioInputChanged(value === 'none' ? null : value)
  }

  return (
    <FormFieldGroup
      description={I18n.t('Status')}
      disabled={false}
      layout="stacked"
      rowSpacing="none"
    >
      {radioInputOptions().map(status => (
        <View
          as="div"
          key={status.key}
          height="2.925rem"
          background="primary"
          className={getRadioInputClasses(status.color ?? 'transparent')}
          themeOverride={{
            backgroundPrimary: status.color,
          }}
        >
          <RadioInput
            checked={status.checked}
            disabled={disabled || status.disabled}
            name="GradeOverrideTrayRadioInput"
            label={status.name}
            onChange={onRadioInputChanged}
            value={status.key}
          />
        </View>
      ))}
    </FormFieldGroup>
  )
}
