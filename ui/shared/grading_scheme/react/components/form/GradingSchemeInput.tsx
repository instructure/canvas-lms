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

import React, {Fragment, ChangeEvent, useState, useImperativeHandle} from 'react'
import shortid from '@canvas/shortid'

import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {calculateMaxScoreForDataRow} from '../../helpers/calculateMaxScoreForDataRow'
import {GradingSchemeDataRowInput} from './GradingSchemeDataRowInput'
import {GradingSchemeDataRow} from '../../../gradingSchemeApiModel'
import {GradingSchemeValidationAlert} from './GradingSchemeValidationAlert'
import {gradingSchemeIsValid} from './validations/gradingSchemeValidations'

const I18n = useI18nScope('GradingSchemeManagement')

export interface ComponentProps {
  initialFormData: GradingSchemeFormInput
  onSave: (gradingSchemeFormInput: GradingSchemeFormInput) => any
}
export interface GradingSchemeFormInput {
  title: string
  data: GradingSchemeDataRow[]
}

interface GradingSchemeFormDataWithUniqueRowIds {
  title: string
  data: GradingSchemeDataRowWithUniqueId[]
}
interface GradingSchemeDataRowWithUniqueId extends GradingSchemeDataRow {
  uniqueId: string
}

export type GradingSchemeInputHandle = {
  savePressed: () => void
}

/**
 * Form input fields for creating or updating GradingSchemes.
 *
 * This form input component is an imperative component because its
 * 'save' button is located in an external component (such as a modal
 * action button row).  This component handles all form validation
 * prior to calling the parent's onSave callback
 *
 * @param initialFormData Data to set as initial default values for the form
 * @constructor
 */

export const GradingSchemeInput = React.forwardRef<GradingSchemeInputHandle, ComponentProps>(
  ({initialFormData, onSave}, ref) => {
    const [showAlert, setShowAlert] = React.useState<boolean>(false)
    const [inputFormData, setInputFormData] = useState<GradingSchemeFormDataWithUniqueRowIds>({
      title: initialFormData.title,
      // deep clone the template's row data. (we don't want to modify the provided data by reference)
      data: initialFormData.data.map(dataRow => {
        return {
          ...dataRow,
          uniqueId: shortid(),
        }
      }),
    })

    useImperativeHandle(ref, () => ({
      savePressed: () => {
        const isValid = gradingSchemeIsValid(inputFormData)
        setShowAlert(!isValid)
        if (isValid) {
          onSave(inputFormData)
        }
      },
    }))

    const changeRowLetterGrade = (rowIndex: number, newRowName: string) => {
      const updatedScheme = {
        ...inputFormData,
      }
      updatedScheme.data[rowIndex].name = newRowName
      setInputFormData(updatedScheme)
    }

    const changeRowMinScore = (rowIndex: number, rowMinScore: number) => {
      const updatedScheme = {
        ...inputFormData,
      }
      updatedScheme.data[rowIndex].value = rowMinScore
      setInputFormData(updatedScheme)
    }
    const changeTitle = (e: ChangeEvent<HTMLInputElement>) => {
      const title = e.currentTarget.value.trim()
      const updatedScheme = {
        ...inputFormData,
        title,
      }
      setInputFormData(updatedScheme)
    }
    const addDataRow = (index: number) => {
      const [rowBefore, rowAfter] = inputFormData.data.slice(index, index + 2)
      const score = rowAfter ? (rowBefore.value - rowAfter.value) / 2 + rowAfter.value : 0
      inputFormData.data.splice(index + 1, 0, {uniqueId: shortid(), name: '', value: score})

      const updatedScheme = {
        ...inputFormData,
        data: inputFormData.data,
      }
      setInputFormData(updatedScheme)
    }

    const removeDataRow = (index: number) => {
      const updatedScheme = {
        ...inputFormData,
      }
      updatedScheme.data.splice(index, 1)
      setInputFormData(updatedScheme)
    }

    return (
      <View>
        {showAlert && inputFormData ? (
          <GradingSchemeValidationAlert
            formData={inputFormData}
            onClose={() => setShowAlert(false)}
          />
        ) : (
          <></>
        )}

        <TextInput
          isRequired={true}
          renderLabel={I18n.t('Grading Scheme Name')}
          onChange={changeTitle}
          defaultValue={initialFormData.title}
        />
        <View as="div" margin="medium none none none">
          <table
            className="grading-scheme-data-input-table"
            style={{textAlign: 'left', width: '100%'}}
          >
            <caption>
              <ScreenReaderContent>
                {I18n.t(
                  'A table that contains the grading scheme data. First is a name of the grading scheme and buttons for editing and deleting the scheme. Each row contains a name, a maximum percentage, and a minimum percentage. In addition, each row contains a button to add a new row below, and a button to delete the current row.'
                )}
              </ScreenReaderContent>
            </caption>
            <thead>
              <tr>
                <th style={{width: '10%'}}>
                  <ScreenReaderContent>{I18n.t('Add row action')}</ScreenReaderContent>
                </th>
                <th style={{width: '40%'}}>{I18n.t('Letter Grade')}</th>
                <th style={{width: '40%'}}>{I18n.t('Range')}</th>
                <th style={{width: '10%'}}>
                  <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
                </th>
              </tr>
            </thead>
            <tbody>
              {inputFormData.data.map((dataRow, idx, array) => (
                <Fragment key={dataRow.uniqueId}>
                  <GradingSchemeDataRowInput
                    dataRow={{name: dataRow.name, value: dataRow.value}}
                    maxScore={calculateMaxScoreForDataRow(idx, array)}
                    isFirstRow={idx === 0}
                    onRowMinScoreChange={minScore => changeRowMinScore(idx, minScore)}
                    onRowLetterGradeChange={letterGrade => changeRowLetterGrade(idx, letterGrade)}
                    onRowDeleteRequested={() => removeDataRow(idx)}
                    onRowAddRequested={() => addDataRow(idx)}
                    isLastRow={idx === array.length - 1}
                  />
                </Fragment>
              ))}
            </tbody>
          </table>
        </View>
      </View>
    )
  }
)
