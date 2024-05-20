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
import {outOfText, passFailStatusOptions, disableGrading} from '../../../utils/gradebookUtils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  ApiCallStatus,
  type AssignmentConnection,
  type GradebookUserSubmissionDetails,
} from '../../../types'
import type {Spacing} from '@instructure/emotion'

const I18n = useI18nScope('enhanced_individual_gradebook')

const {Option: SimpleSelectOption} = SimpleSelect as any

type Props = {
  assignment: AssignmentConnection
  submission: GradebookUserSubmissionDetails
  passFailStatusIndex: number
  gradeInput: string
  submitScoreStatus: ApiCallStatus
  context: string
  elementWrapper?: 'span' | 'div'
  margin?: Spacing
  handleSetGradeInput: (grade: string) => void
  handleSubmitGrade?: () => void
  handleChangePassFailStatus: (
    e: React.SyntheticEvent<Element, Event>,
    data: {value?: string | number}
  ) => void
}

export default function DefaultGradeInput({
  assignment,
  submission,
  passFailStatusIndex,
  gradeInput,
  submitScoreStatus,
  context,
  elementWrapper = 'div',
  margin = '0 0 small 0',
  handleSetGradeInput,
  handleSubmitGrade,
  handleChangePassFailStatus,
}: Props) {
  const renderOutOfText = () => {
    return (
      <View as="span" margin="0 0 0 small" data-testid={`${context}_out_of_text`}>
        {outOfText(assignment, submission)}
      </View>
    )
  }

  return (
    <>
      {assignment.gradingType === 'pass_fail' ? (
        <View as={elementWrapper} margin={margin}>
          <SimpleSelect
            renderLabel={
              <ScreenReaderContent>
                {`${I18n.t('Student Grade Pass-Fail Grade Options')}: ${outOfText(
                  assignment,
                  submission
                )}`}
              </ScreenReaderContent>
            }
            size="medium"
            isInline={true}
            onChange={handleChangePassFailStatus}
            value={passFailStatusOptions[passFailStatusIndex].value}
            interaction={disableGrading(assignment, submitScoreStatus) ? 'disabled' : undefined}
            data-testid={`${context}_select`}
            onBlur={() => handleSubmitGrade?.()}
          >
            {passFailStatusOptions.map(option => (
              <SimpleSelectOption id={option.label} key={option.label} value={option.value}>
                {option.label}
              </SimpleSelectOption>
            ))}
          </SimpleSelect>
          {renderOutOfText()}
        </View>
      ) : (
        <View as={elementWrapper} className="grade" margin={margin}>
          <TextInput
            renderLabel={
              <ScreenReaderContent>
                {`${I18n.t('Student Grade Text Input')}: ${outOfText(assignment, submission)}`}
              </ScreenReaderContent>
            }
            display="inline-block"
            width="14rem"
            value={gradeInput}
            disabled={disableGrading(assignment, submitScoreStatus)}
            data-testid={`${context}_input`}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              handleSetGradeInput(e.target.value)
            }
            onBlur={() => handleSubmitGrade?.()}
          />
          {renderOutOfText()}
        </View>
      )}
    </>
  )
}
