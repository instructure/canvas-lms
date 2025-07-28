/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

// This was copied from the AssessmentGradeInput component in SpeedGrader 2 and
// adapted to work on Canvas LMS. Some functionality was added to support Checkpoints.
// The idea is that this can be moved easily to SpeedGrader 2 in the future.

import {Select} from '@instructure/ui-select'
import {Text} from '@instructure/ui-text'
import {TextInput, type TextInputProps} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import React, {useCallback, useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {
  Assignment,
  SubAssignmentSubmission,
  SubmissionGradeParams,
} from './SpeedGraderCheckpointsContainer'
import Big from 'big.js'
import parseNumber from 'parse-decimal-number'

// The types/methods following up can be deleted when this is moved to SpeedGrader 2...
//   - numberFormatter
//   - Submission
//   - roundBigNumber
//   - isScientific
//   - getLocaleSeparators
//   - parseFormattedNumber

const numberFormatter = Intl.NumberFormat(ENV.LOCALE)

type Submission = SubAssignmentSubmission

const roundBigNumber = (value: number, precision: number) => {
  try {
    return Big(value).round(precision, 0).toNumber()
  } catch {
    return Number.NaN
  }
}

const isScientific = (inputString: string) => {
  const scientificPattern = /^[+-]?\d+(\.\d*)?([eE][+-]?\d+)$/
  return inputString.match(scientificPattern)
}

const getLocaleSeparators = (numberFormatter: Intl.NumberFormat) => {
  // Generate a localized number to find out the thousand and decimal separators
  const parts = numberFormatter.formatToParts(1234567.89)
  const thousands = parts.find(part => part.type === 'group')?.value
  const decimal = parts.find(part => part.type === 'decimal')?.value

  return {thousands: thousands || ',', decimal: decimal || '.'}
}

const parseFormattedNumber = (input: number | string, numberFormatter: Intl.NumberFormat) => {
  if (input === null) {
    return Number.NaN
  }

  if (typeof input === 'number') {
    return input
  }

  // TODO: Get thousands and decimal locale
  let num = parseNumber(input.toString(), getLocaleSeparators(numberFormatter))

  // fallback to default delimiters if invalid with locale specific ones
  if (Number.isNaN(Number(num))) {
    num = parseNumber(input)
  }

  // final fallback to old parseFloat - this allows us to still support scientific 'e' notation
  if (Number.isNaN(Number(num)) && isScientific(input.toString())) {
    num = Number.parseFloat(input)
  }

  return num
}

const I18n = createI18nScope('SpeedGraderCheckpoints')

export type AssessmentGradeInputProps = {
  assignment: Assignment
  showAlert: (message: string, variant?: string) => void
  submission: Submission
  courseId: string
  updateSubmissionGrade?: (params: SubmissionGradeParams) => void
  inputDisplay?: 'inline-block' | 'block'
  isWidthDefault?: boolean
  hasHeader?: boolean
  header?: string
  isDisabled?: boolean
  setLastSubmission: (params: SubAssignmentSubmission) => void
}

export const AssessmentGradeInput = ({
  assignment,
  showAlert,
  submission,
  courseId,
  updateSubmissionGrade,
  inputDisplay = 'inline-block',
  isWidthDefault = true,
  hasHeader = false,
  header = '',
  isDisabled = false,
  setLastSubmission,
}: AssessmentGradeInputProps) => {
  const gradeToUse = useCallback(
    (gradeToUseSubmission: SubAssignmentSubmission) => {
      return (isDisabled ? gradeToUseSubmission?.grade : gradeToUseSubmission?.entered_grade) || ''
    },
    [isDisabled],
  )

  // @ts-expect-error
  const [gradeValue, setGradeValue] = useState<string>(gradeToUse(submission))

  const formatGradeForSubmission = useCallback(
    (grade: string, excused: boolean) => {
      if (grade === '' || grade === 'MI' || grade === 'EX') {
        return excused ? 'EX' : grade
      }

      let formattedGrade: string = grade
      if (['percent', 'points'].includes(assignment.grading_type)) {
        // Percent sign could be located on left or right, with or without space
        // https://en.wikipedia.org/wiki/Percent_sign
        formattedGrade = grade.replace(/%/g, '')
        const tmpNum = parseFormattedNumber(formattedGrade, numberFormatter)
        formattedGrade = roundBigNumber(tmpNum, 2).toString()

        if (assignment.grading_type === 'percent' && formattedGrade !== 'NaN') {
          formattedGrade += '%'
        }
      }
      return formattedGrade
    },
    [assignment.grading_type],
  )

  useEffect(() => {
    // @ts-expect-error
    setGradeValue(formatGradeForSubmission(gradeToUse(submission), submission?.excused || false))
  }, [formatGradeForSubmission, gradeToUse, submission, submission.excused, submission.grade])

  const isValidPreliminaryGrade = (formattedGrade: string): boolean => {
    if (formattedGrade === '' || formattedGrade === 'EX' || formattedGrade === 'MI') {
      return true
    }

    if (['percent', 'points'].includes(assignment.grading_type)) {
      return !Number.isNaN(Number(formattedGrade.replace(/%/g, '')))
    }

    // Leave it to the server to figure out for sure if it fits a grading scheme
    return true
  }

  const submitGrade = (grade: string) => {
    if (grade === submission.grade) return
    const excuse = grade.toUpperCase() === 'EX'

    const formattedGrade = formatGradeForSubmission(grade, excuse)
    if (!isValidPreliminaryGrade(formattedGrade)) {
      setGradeValue(
        formatGradeForSubmission(
          // @ts-expect-error
          gradeToUse(submission),
          submission?.excused || false,
        ),
      )
      showAlert(I18n.t('Invalid grade value'), 'error')
      return
    }

    if (updateSubmissionGrade) {
      setLastSubmission({
        sub_assignment_tag: submission.sub_assignment_tag,
        grade: grade === '' || excuse ? null : grade,
      } as SubAssignmentSubmission)
      updateSubmissionGrade({
        subAssignmentTag: submission.sub_assignment_tag,
        courseId,
        assignmentId: assignment.id,
        studentId: submission.user_id,
        grade: grade === '' || excuse ? null : grade,
      })
    }
  }

  let gradeText = ''

  if (assignment?.grading_type === 'points') {
    gradeText = I18n.t('Grade out of {{pointsPossible}}', {
      pointsPossible: assignment?.points_possible || 0,
    })
  } else if (assignment?.grading_type !== 'gpa_scale') {
    gradeText = I18n.t('Grade ({{grade}} / {{pointsPossible}})', {
      grade: submission?.score || 0,
      pointsPossible: assignment?.points_possible || 0,
    })
  }

  const label = gradeText || I18n.t('Grade')

  let interaction: TextInputProps['interaction'] = 'enabled'
  if (isDisabled || submission.excused) {
    interaction = 'disabled'
  }

  return (
    <>
      {['points', 'percent', 'letter_grade', 'gpa_scale'].includes(assignment.grading_type) ? (
        <>
          <div>
            {hasHeader && (
              <Text size="small" weight="bold">
                {header}
              </Text>
            )}
          </div>
          <TextInput
            data-testid="grade-input"
            renderLabel={() =>
              hasHeader ? (
                <Text size="x-small" weight="normal">
                  {label}
                </Text>
              ) : (
                label
              )
            }
            onKeyDown={e => {
              if (e.key === 'Enter') {
                submitGrade(gradeValue)
              }
            }}
            onBlur={() => {
              submitGrade(gradeValue)
            }}
            value={gradeValue}
            onChange={changedValue => {
              setGradeValue(`${changedValue.target.value}`)
            }}
            width={isWidthDefault ? '10rem' : undefined}
            display={inputDisplay}
            interaction={interaction}
          />
        </>
      ) : assignment.grading_type === 'pass_fail' ? (
        <>
          {hasHeader && (
            <Text size="small" weight="bold">
              {header}
            </Text>
          )}
          <PassFailSelect
            submission={submission}
            assignment={assignment}
            handleSelect={value => {
              setGradeValue(value)
              submitGrade(value)
            }}
            hasHeader={hasHeader}
            isDisabled={isDisabled}
          />
        </>
      ) : assignment.grading_type === 'not_graded' && submission.score !== null ? (
        <View as="div" padding="0 0 medium 0">
          <Text size="small" weight="normal">
            {I18n.t('Grade ({{grade}})', {
              grade: submission.score,
            })}
          </Text>
        </View>
      ) : null}
    </>
  )
}

const PassFailSelect = ({
  submission,
  assignment,
  handleSelect,
  hasHeader = false,
  isDisabled = false,
}: {
  submission?: Submission
  assignment?: Assignment
  handleSelect: (value: string) => void
  hasHeader?: boolean
  isDisabled?: boolean
}) => {
  const [selectedOption, setSelectedOption] = useState(submission?.grade || '')
  const [highlightedOption, setHighlightedOption] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)

  const handleShowOption = () => setIsShowingOptions(true)
  const handleHideOption = () => setIsShowingOptions(false)
  const handleHighlightOption = (value: string) => setHighlightedOption(value)
  const handleSelectOption = (id: string) => {
    const option = options.find(o => o.id === id)
    if (!option) return
    setSelectedOption(option.value)
    setHighlightedOption(option.value)
    setIsShowingOptions(false)
    handleSelect(option.value)
  }

  useEffect(() => {
    setSelectedOption(submission?.grade || '')
  }, [submission])

  const options = [
    {id: 'blank', value: '', label: '---'},
    {id: 'complete', value: 'complete', label: I18n.t('Complete')},
    {id: 'incomplete', value: 'incomplete', label: I18n.t('Incomplete')},
  ]

  const label = I18n.t('Grade ({{score}} / {{pointsPossible}})', {
    score: submission?.score || 0,
    pointsPossible: assignment?.points_possible || 0,
  })

  return (
    <Select
      renderLabel={
        hasHeader ? (
          <Text size="x-small" weight="normal">
            {label}
          </Text>
        ) : (
          <Text size="small" weight="normal">
            {label}
          </Text>
        )
      }
      inputValue={options.find(({value}) => value === selectedOption)?.label || ''}
      isShowingOptions={isShowingOptions}
      onRequestHideOptions={handleHideOption}
      onRequestShowOptions={handleShowOption}
      onRequestHighlightOption={(e, {id}) => handleHighlightOption(id || '')}
      onRequestSelectOption={(e, {id}) => handleSelectOption(id || '')}
      interaction={isDisabled ? 'disabled' : 'enabled'}
      data-testid="pass-fail-select"
    >
      {options.map(option => (
        <Select.Option
          id={option.id}
          key={option.id}
          value={option.value}
          isHighlighted={highlightedOption === option.id}
        >
          {option.label}
        </Select.Option>
      ))}
    </Select>
  )
}

export default AssessmentGradeInput
