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

import React, {useCallback, useEffect, useState} from 'react'

import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import type {GradingType} from '../../../../../api'
import {SimpleSelect} from '@instructure/ui-simple-select'

const I18n = useI18nScope('enhanced_individual_gradebook')

const {Option: SimpleSelectOption} = SimpleSelect as any

type InputType = 'text' | 'select'
type Props = {
  // TODO: I need to use cellMapForSubmission shared util function here to determine if
  // inputs should be disabled.... however, i need to refactor that function and other functions
  // to make the types more specific to only the properties that are needed for caclulations
  disabled: boolean
  gradingType: GradingType
  onGradeInputChange: (gradeInput: string) => void
}
export default function DefaultGradeInput({disabled, gradingType, onGradeInputChange}: Props) {
  const [textInput, setTextInput] = useState<string>('')
  const [selectInput, setSelectInput] = useState<string>('')

  const showInputType = useCallback((): InputType => {
    const textGradingTypes = ['percent', 'points', 'letter_grade', 'gpa_scale']
    if (textGradingTypes.includes(gradingType)) {
      return 'text'
    }

    return 'select'
  }, [gradingType])

  useEffect(() => {
    onGradeInputChange(showInputType() === 'text' ? textInput : selectInput)
  }, [textInput, selectInput, onGradeInputChange, showInputType])

  return (
    <>
      {showInputType() === 'text' ? (
        <TextInput
          data-testid="default-grade-input"
          renderLabel={<ScreenReaderContent>{I18n.t('Default Grade')}</ScreenReaderContent>}
          display="inline-block"
          width="4rem"
          value={textInput}
          disabled={disabled}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setTextInput(e.target.value)}
        />
      ) : (
        <SimpleSelect
          value={selectInput}
          defaultValue={selectInput}
          renderLabel="Uncontrolled Select"
          onChange={(e, {value}) => {
            if (typeof value === 'string') {
              setSelectInput(value)
            }
          }}
        >
          <SimpleSelectOption id="emptyOption" value="">
            ---
          </SimpleSelectOption>
          <SimpleSelectOption id="completeOption" value="complete">
            Complete
          </SimpleSelectOption>
          <SimpleSelectOption id="incompleteOption" value="incomplete">
            Incomplete
          </SimpleSelectOption>
        </SimpleSelect>
      )}
    </>
  )
}
