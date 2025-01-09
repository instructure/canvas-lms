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

import React, {useCallback, useEffect, useState, useRef} from 'react'

import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import type {GradingType} from '../../../api'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('enhanced_individual_gradebook')

const {Option: SimpleSelectOption} = SimpleSelect as any

type InputType = 'text' | 'select'
type Props = {
  // TODO: I need to use cellMapForSubmission shared util function here to determine if
  // inputs should be disabled.... however, i need to refactor that function and other functions
  // to make the types more specific to only the properties that are needed for caclulations
  disabled: boolean
  gradingType: GradingType
  onGradeInputChange: (gradeInput: string, isPassFail: boolean) => void
  header?: string
  outOfTextValue?: string
  name?: string
  defaultValue?: string
}
export default function DefaultGradeInput({
  disabled,
  gradingType,
  onGradeInputChange,
  header,
  outOfTextValue,
  name,
  defaultValue,
}: Props) {
  const [textInput, setTextInput] = useState<string>(defaultValue || '')
  const [selectInput, setSelectInput] = useState<string>(defaultValue || '')

  // Error Messages for text input
  const [textInputMessage, setTextInputMessage] = useState<FormMessage[]>([])

  const pageDidLoad = React.useRef(false)

  const showInputType = useCallback((): InputType => {
    const textGradingTypes = ['percent', 'points', 'letter_grade', 'gpa_scale']
    if (textGradingTypes.includes(gradingType)) {
      return 'text'
    }

    return 'select'
  }, [gradingType])

  const validInput = (value: string) => {
    if (value === "") {
      setTextInputMessage([
        {
          text: I18n.t('Enter a grade'),
          type: 'error',
        },
      ])
      return false
    }
    return true
  }

  // This event only works for the text input
  const triggerGradeChangeEvent = () => {
    if (!validInput(textInput)) {
      return
    }

    if (showInputType() === 'text') {
      return onGradeInputChange(textInput, false)
    }
  }

  const onTextInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setTextInput(e.target.value)
    setTextInputMessage([])
  }

  // This useEffect is used for the select input
  useEffect(() => {
    // Prevents the useEffect from running on the first render
    if (pageDidLoad.current && showInputType() === 'select') {
      return onGradeInputChange(selectInput, true)
    }
    pageDidLoad.current = true
  }, [selectInput, onGradeInputChange, showInputType])

  const renderHeader = () => {
    return (
      header && (
        <div>
          <Text size="small" weight="bold">
            {header}
          </Text>
        </div>
      )
    )
  }

  const renderSubHeader = () => {
    return (
      outOfTextValue && (
        <Text size="x-small" weight="normal">
          {I18n.t(`out of %{outOfTextValue}`, {outOfTextValue})}
        </Text>
      )
    )
  }

  return (
    <>
      {showInputType() === 'text' ? (
        <View as="div" data-testid="default-grade-input-text">
          {renderHeader()}
          <TextInput
            data-testid="default-grade-input"
            renderLabel={
              <>
                <ScreenReaderContent>
                  {`${header || I18n.t('Default Grade')}: ${outOfTextValue}`}
                </ScreenReaderContent>
                {renderSubHeader()}
              </>
            }
            display="inline-block"
            width="6rem"
            value={textInput}
            disabled={disabled}
            onChange={onTextInputChange}
            name={name}
            onBlur={triggerGradeChangeEvent}
            messages={textInputMessage}
          />
        </View>
      ) : (
        <View as="div" data-testid="default-grade-input-select">
          {renderHeader()}
          <SimpleSelect
            value={selectInput}
            defaultValue={selectInput}
            renderLabel={
              <>
                <ScreenReaderContent>
                  {`${
                    header || I18n.t('Student Grade Pass-Fail Grade Options')
                  }: ${outOfTextValue}`}
                </ScreenReaderContent>
                {renderSubHeader()}
              </>
            }
            onChange={(_e, {value}) => {
              if (typeof value === 'string') {
                setSelectInput(value)
              }
            }}
            name={name}
            disabled={disabled}
            width="10rem"
            data-testid="select-dropdown"
          >
            <SimpleSelectOption id="emptyOption" value="" data-testid="empty-dropdown-option">
              ---
            </SimpleSelectOption>
            <SimpleSelectOption
              id="completeOption"
              value="complete"
              data-testid="complete-dropdown-option"
            >
              Complete
            </SimpleSelectOption>
            <SimpleSelectOption
              id="incompleteOption"
              value="incomplete"
              data-testid="incomplete-dropdown-option"
            >
              Incomplete
            </SimpleSelectOption>
          </SimpleSelect>
        </View>
      )}
    </>
  )
}
