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

import React, {useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {View} from '@instructure/ui-view'
import type {GradebookOptions, Outcome, SortableStudent} from '../../../types'
import {studentDisplayName} from '../../../utils/gradebookUtils'
import {
  useOutcomeDropdownOptions,
  useUserDropdownOptions,
} from '../../hooks/useContentDropdownOptions'

const I18n = useI18nScope('enhanced_individual_gradebook')

export type ContentSelectionComponentProps = {
  students?: SortableStudent[]
  outcomes?: Outcome[]
  selectedStudentId?: string | null
  selectedOutcomeId?: string | null
  gradebookOptions: GradebookOptions
  onStudentChange: (studentId?: string) => void
  onOutcomeChange: (outcomeId?: string) => void
}

export default function ContentSelection({
  students,
  outcomes,
  selectedStudentId,
  selectedOutcomeId,
  gradebookOptions,
  onStudentChange,
  onOutcomeChange,
}: ContentSelectionComponentProps) {
  const [selectedStudentIndex, setSelectedStudentIndex] = useState<number>(0)
  const [selectedOutcomeIndex, setSelectedOutcomeIndex] = useState<number>(0)
  const nextStudentRef = useRef<HTMLButtonElement>(null)
  const previousStudentRef = useRef<HTMLButtonElement>(null)
  const nextOucomeRef = useRef<HTMLButtonElement>(null)
  const previousOucomeRef = useRef<HTMLButtonElement>(null)

  const {
    selectedSection,
    customOptions: {showConcludedEnrollments},
  } = gradebookOptions
  const {studentDropdownOptions} = useUserDropdownOptions({
    students,
    selectedSection,
    showConcludedEnrollments,
  })

  const {outcomeDropdownOptions} = useOutcomeDropdownOptions({outcomes, selectedOutcomeId})

  useEffect(() => {
    if (!outcomeDropdownOptions) {
      return
    }

    if (selectedOutcomeId) {
      const outcomeIndex = outcomeDropdownOptions.findIndex(
        outcomeOption => outcomeOption.id === selectedOutcomeId
      )

      if (outcomeIndex !== -1) {
        setSelectedOutcomeIndex(outcomeIndex)
      } else {
        setSelectedOutcomeIndex(0)
        onOutcomeChange(undefined)
      }
    }
  }, [selectedOutcomeId, outcomeDropdownOptions, setSelectedOutcomeIndex, onOutcomeChange])

  useEffect(() => {
    if (!studentDropdownOptions) {
      return
    }

    if (selectedStudentId) {
      const studentIndex = studentDropdownOptions.findIndex(
        studentOption => studentOption.id === selectedStudentId
      )

      if (studentIndex !== -1) {
        setSelectedStudentIndex(studentIndex)
      } else {
        // if the student is not in the dropdown, reset the student dropdown
        setSelectedStudentIndex(0)
        onStudentChange(undefined)
      }
    }
  }, [selectedStudentId, studentDropdownOptions, setSelectedStudentIndex, onStudentChange])

  if (!studentDropdownOptions || !outcomeDropdownOptions) {
    return <LoadingIndicator />
  }

  const handleChangeOutcome = (event?: React.ChangeEvent<HTMLSelectElement>, newIndex?: number) => {
    const selectedIndex = (event ? event.target.selectedIndex : newIndex) ?? 0
    setSelectedOutcomeIndex(selectedIndex)
    const selectedOutcome = outcomeDropdownOptions[selectedIndex]?.data
    onOutcomeChange(selectedOutcome?.id)

    if (selectedIndex <= 0) {
      nextOucomeRef.current?.focus()
    } else if (selectedIndex >= outcomeDropdownOptions.length - 1) {
      previousOucomeRef.current?.focus()
    }
  }

  const handleChangeStudent = (event?: React.ChangeEvent<HTMLSelectElement>, newIndex?: number) => {
    const selectedIndex = (event ? event.target.selectedIndex : newIndex) ?? 0
    setSelectedStudentIndex(selectedIndex)
    const selectedStudent = studentDropdownOptions[selectedIndex]?.data

    onStudentChange(selectedStudent?.id)

    if (selectedIndex <= 0) {
      nextStudentRef.current?.focus()
    } else if (selectedIndex >= studentDropdownOptions.length - 1) {
      previousStudentRef.current?.focus()
    }
  }

  const {hideStudentNames} = gradebookOptions.customOptions

  return (
    <>
      <View as="div" className="row-fluid">
        <View as="div" className="span12">
          <View as="h2">{I18n.t('Content Selection')}</View>
        </View>
      </View>

      <View
        as="div"
        className="row-fluid pad-box bottom-only"
        data-testid="learning-mastery-content-selection-student"
      >
        <View as="div" className="span4 text-right-responsive">
          <label htmlFor="student_select" style={{textAlign: 'right', display: 'block'}}>
            {I18n.t('Select a student')}
          </label>
        </View>
        <View as="div" className="span8">
          <select
            className="student_select"
            onChange={handleChangeStudent}
            value={studentDropdownOptions[selectedStudentIndex]?.id}
            data-testid="learning-mastery-content-selection-student-select"
          >
            {studentDropdownOptions.map(option => (
              <option key={option.id} value={option.id}>
                {option.data
                  ? studentDisplayName(option.data, hideStudentNames)
                  : option.sortableName}
              </option>
            ))}
          </select>
          <View as="div" className="row-fluid pad-box bottom-only student_navigation">
            <View as="div" className="span4">
              <button
                data-testid="learning-mastery-previous-student-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedStudentIndex <= 0}
                onClick={() => handleChangeStudent(undefined, selectedStudentIndex - 1)}
                ref={previousStudentRef}
              >
                {I18n.t('Previous Student')}
              </button>
            </View>
            <View as="div" className="span4">
              <button
                data-testid="learning-mastery-next-student-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedStudentIndex >= studentDropdownOptions.length - 1}
                onClick={() => handleChangeStudent(undefined, selectedStudentIndex + 1)}
                ref={nextStudentRef}
              >
                {I18n.t('Next Student')}
              </button>
            </View>
          </View>
        </View>
      </View>

      <View
        as="div"
        className="row-fluid pad-box bottom-only"
        data-testid="learning-mastery-content-selection-outcome"
      >
        <View as="div" className="span4 text-right-responsive">
          <label htmlFor="outcome_select" style={{textAlign: 'right', display: 'block'}}>
            {I18n.t('Select an outcome')}
          </label>
        </View>
        <View as="div" className="span8">
          <select
            className="outcome_select"
            onChange={handleChangeOutcome}
            value={outcomeDropdownOptions[selectedOutcomeIndex]?.id}
            data-testid="learning-mastery-content-selection-outcome-select"
          >
            {outcomeDropdownOptions.map(option => (
              <option key={option.id} value={option.id}>
                {option.name}
              </option>
            ))}
          </select>
          <View as="div" className="row-fluid pad-box bottom-only outcome_navigation">
            <View as="div" className="span4">
              <button
                data-testid="learning-mastery-previous-outcome-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedOutcomeIndex <= 0}
                onClick={() => handleChangeOutcome(undefined, selectedOutcomeIndex - 1)}
                ref={previousOucomeRef}
              >
                {I18n.t('Previous Outcome')}
              </button>
            </View>
            <View as="div" className="span4">
              <button
                data-testid="learning-mastery-next-outcome-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedOutcomeIndex >= outcomeDropdownOptions.length - 1}
                onClick={() => handleChangeOutcome(undefined, selectedOutcomeIndex + 1)}
                ref={nextOucomeRef}
              >
                {I18n.t('Next Outcome')}
              </button>
            </View>
          </View>
        </View>
      </View>
    </>
  )
}
