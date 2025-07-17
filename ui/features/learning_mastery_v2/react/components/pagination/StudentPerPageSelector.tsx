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
import {useScope as createI18nScope} from '@canvas/i18n'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface StudentPerPageSelectorProps {
  options: number[]
  value: number
  onChange: (value: number) => void
}

export const StudentPerPageSelector: React.FC<StudentPerPageSelectorProps> = ({
  options,
  value,
  onChange,
}) => {
  return (
    <>
      <Text>{I18n.t('Showing')}</Text>
      <SimpleSelect
        renderLabel={() => (
          <ScreenReaderContent>{I18n.t('Select number of students per page')}</ScreenReaderContent>
        )}
        value={value}
        onChange={(_, {value}) => onChange(value as number)}
        data-testid="per-page-selector"
        width="80px"
      >
        {options.map(option => (
          <SimpleSelect.Option key={option} id={`per-page-${option}`} value={option}>
            {option.toString()}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </>
  )
}
