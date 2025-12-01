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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {OutcomeArrangement} from '../../utils/constants'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface OutcomeArrangementSelectorProps {
  value?: OutcomeArrangement
  onChange: (arrangement: OutcomeArrangement) => void
}

export const OutcomeArrangementSelector: React.FC<OutcomeArrangementSelectorProps> = ({
  value = OutcomeArrangement.UPLOAD_ORDER,
  onChange,
}) => {
  const options = [
    {
      id: OutcomeArrangement.ALPHABETICAL,
      value: OutcomeArrangement.ALPHABETICAL,
      name: I18n.t('Alphabetical'),
    },
    {id: OutcomeArrangement.CUSTOM, value: OutcomeArrangement.CUSTOM, name: I18n.t('Custom')},
    {
      id: OutcomeArrangement.UPLOAD_ORDER,
      value: OutcomeArrangement.UPLOAD_ORDER,
      name: I18n.t('Upload Order'),
    },
  ]

  const handleChange = (_event: React.SyntheticEvent, data: {value?: string | number}) => {
    const selectedValue = data.value as OutcomeArrangement
    if (Object.values(OutcomeArrangement).includes(selectedValue)) {
      onChange(selectedValue)
    }
  }

  return (
    <View>
      <SimpleSelect
        renderLabel={I18n.t('Arrange Outcomes by')}
        value={value}
        onChange={handleChange}
      >
        {options.map(option => (
          <SimpleSelect.Option
            id={option.id}
            value={option.value}
            key={`outcome_arrangement_${option.id}`}
          >
            {option.name}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
      <View as="div" margin="xxx-small 0 0 0">
        <Text size="x-small" color="secondary">
          {I18n.t('(You may drag & drop columns to re-arrange)')}
        </Text>
      </View>
    </View>
  )
}
