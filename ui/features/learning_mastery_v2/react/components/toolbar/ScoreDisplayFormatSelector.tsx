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
import {ScoreDisplayFormat} from '@canvas/outcomes/react/utils/constants'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface ScoreDisplayFormatSelectorProps {
  value?: ScoreDisplayFormat
  onChange: (format: ScoreDisplayFormat) => void
}

export const ScoreDisplayFormatSelector: React.FC<ScoreDisplayFormatSelectorProps> = ({
  value = ScoreDisplayFormat.ICON_ONLY,
  onChange,
}) => {
  const inputs = [
    {value: ScoreDisplayFormat.ICON_ONLY, label: I18n.t('Icons Only')},
    {value: ScoreDisplayFormat.ICON_AND_POINTS, label: I18n.t('Icons + Points')},
    {value: ScoreDisplayFormat.ICON_AND_LABEL, label: I18n.t('Icons + Descriptor')},
  ]

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.value as ScoreDisplayFormat)
  }

  return (
    <RadioInputGroup
      onChange={handleChange}
      name="score-display-format"
      value={value.toString()}
      description={I18n.t('Scoring')}
    >
      {inputs.map(input => (
        <RadioInput key={input.value} value={input.value.toString()} label={input.label} />
      ))}
    </RadioInputGroup>
  )
}
