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
import React from 'react'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SecondaryInfoDisplay} from '@canvas/outcomes/react/utils/constants'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface SecondaryInfoSelectorProps {
  value: SecondaryInfoDisplay
  onChange: (value: SecondaryInfoDisplay) => void
}

export const SecondaryInfoSelector: React.FC<SecondaryInfoSelectorProps> = ({value, onChange}) => {
  const inputs = [
    {value: SecondaryInfoDisplay.SIS_ID, label: I18n.t('SIS ID')},
    {value: SecondaryInfoDisplay.INTEGRATION_ID, label: I18n.t('Integration ID')},
    {value: SecondaryInfoDisplay.LOGIN_ID, label: I18n.t('Login ID')},
    {value: SecondaryInfoDisplay.NONE, label: I18n.t('None')},
  ]

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.value as SecondaryInfoDisplay)
  }

  return (
    <RadioInputGroup
      onChange={handleChange}
      name="secondary-info-display"
      defaultValue={value.toString()}
      description={I18n.t('Secondary info')}
    >
      {inputs.map(input => (
        <RadioInput key={input.value} value={input.value.toString()} label={input.label} />
      ))}
    </RadioInputGroup>
  )
}
