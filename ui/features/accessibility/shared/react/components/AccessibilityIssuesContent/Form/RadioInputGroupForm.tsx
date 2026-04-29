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

import React, {forwardRef, useCallback} from 'react'

import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'

import {FormComponentHandle, FormComponentProps} from './index'

const RadioInputGroupForm: React.FC<FormComponentProps & React.RefAttributes<FormComponentHandle>> =
  forwardRef<FormComponentHandle, FormComponentProps>(
    ({issue, value, error, onChangeValue, isDisabled}: FormComponentProps, _) => {
      const handleChange = useCallback(
        (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
          onChangeValue(value)
        },
        [onChangeValue],
      )

      if (!issue.form.options?.length || !issue.form.label) return null

      return (
        <RadioInputGroup
          data-testid="radio-input-group"
          name={issue.form.label}
          description={
            <Text data-testid="radio-description" as="span" weight="weightRegular">
              {issue.form.label}
            </Text>
          }
          value={value}
          onChange={handleChange}
          messages={error ? [{text: error, type: 'newError'}] : []}
          disabled={isDisabled}
        >
          {issue.form.options.map(option => (
            <RadioInput
              key={option}
              data-testid={`radio-${option}`}
              value={option}
              label={option}
            />
          ))}
        </RadioInputGroup>
      )
    },
  )

export default RadioInputGroupForm
