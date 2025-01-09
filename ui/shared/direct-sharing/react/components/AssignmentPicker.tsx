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

import React, {useState, useEffect} from 'react'
import {Select} from '@instructure/ui-select'
import {getAssignmentsByCourseId, type AssignmentItem} from './queries/assignmentsByCourseIdQuery'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_and_module_picker')

interface AssignmentPickerProps {
  courseId: string
  onAssignmentSelected: (assignment: AssignmentItem | null) => void
}

export default function AssignmentPicker({courseId, onAssignmentSelected}: AssignmentPickerProps) {
  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedAssignmentId, setHighlightedAssignmentId] = useState<string | null>(null)
  const [selectedAssignment, setSelectedAssignment] = useState<AssignmentItem | null>(null)
  const [filteredAssignments, setFilteredAssignments] = useState<AssignmentItem[]>([])
  const [allAssignments, setAllAssignments] = useState<AssignmentItem[]>([])

  useEffect(() => {
    async function fetchAssignments() {
      const assignments = await getAssignmentsByCourseId(courseId)
      setAllAssignments(assignments)
      setFilteredAssignments(assignments)
    }

    if (courseId) {
      fetchAssignments()
    }
  }, [courseId])

  const getAssignmentById = (queryId: string): AssignmentItem | undefined => {
    return filteredAssignments.find(({_id}) => _id === queryId)
  }

  const filterAssignments = (value: string): AssignmentItem[] => {
    if (!value.trim()) {
      return allAssignments
    }
    return allAssignments.filter(assignment =>
      assignment.name.toLowerCase().startsWith(value.toLowerCase()),
    )
  }

  const matchValue = () => {
    if (filteredAssignments.length === 1) {
      const onlyAssignment = filteredAssignments[0]
      if (onlyAssignment.name.toLowerCase() === inputValue.toLowerCase()) {
        setSelectedAssignment(onlyAssignment)
        onAssignmentSelected(onlyAssignment)
        setFilteredAssignments(filterAssignments(''))
        return {
          inputValue: onlyAssignment.name,
          filteredAssignments: filterAssignments(''),
        }
      }
    }

    if (inputValue.length === 0) {
      setSelectedAssignment(null)
      onAssignmentSelected(null)
      return {selectedAssignment: null}
    }

    if (selectedAssignment) {
      return {inputValue: selectedAssignment.name}
    }

    if (highlightedAssignmentId) {
      const highlightedAssignment = getAssignmentById(highlightedAssignmentId)
      if (highlightedAssignment && inputValue === highlightedAssignment.name) {
        setInputValue('')
        setFilteredAssignments(filterAssignments(''))
        return {
          inputValue: '',
          filteredAssignments: filterAssignments(''),
        }
      }
    }
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedAssignmentId(null)
    matchValue()
  }

  const handleBlur = () => {
    setHighlightedAssignmentId(null)
  }

  const handleHighlightAssignment = (event: React.SyntheticEvent, data: {id?: string}) => {
    event.persist()
    const {id} = data
    if (!id) return
    const assignment = getAssignmentById(id)
    if (!assignment) return
    setHighlightedAssignmentId(id)
    setInputValue(event.type === 'keydown' ? assignment.name : inputValue)
  }

  const handleSelectAssignment = (event: React.SyntheticEvent, data: {id?: string}) => {
    const {id} = data
    if (!id) return
    const assignment = getAssignmentById(id)
    if (!assignment) return
    setSelectedAssignment(assignment)
    onAssignmentSelected(assignment)
    setInputValue(assignment.name)
    setIsShowingOptions(false)
    setFilteredAssignments(filteredAssignments)
  }

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    const newAssignments = filterAssignments(value)
    setInputValue(value)
    setFilteredAssignments(newAssignments)
    setHighlightedAssignmentId(newAssignments.length > 0 ? newAssignments[0]._id : null)
    setIsShowingOptions(true)
    setSelectedAssignment(value === '' ? null : selectedAssignment)
  }

  return (
    <Select
      renderLabel={I18n.t('Select an Assignment (Optional)')}
      placeholder={I18n.t('All Assignments')}
      inputValue={inputValue}
      isShowingOptions={isShowingOptions}
      onBlur={handleBlur}
      onInputChange={handleInputChange}
      onRequestShowOptions={handleShowOptions}
      onRequestHideOptions={handleHideOptions}
      onRequestHighlightOption={handleHighlightAssignment}
      onRequestSelectOption={handleSelectAssignment}
    >
      {filteredAssignments.length > 0 ? (
        filteredAssignments.map(assignment => (
          <Select.Option
            id={assignment._id}
            key={assignment._id}
            isHighlighted={assignment._id === highlightedAssignmentId}
            isSelected={!!selectedAssignment && assignment._id === selectedAssignment._id}
            isDisabled={!!assignment.rubric_id}
          >
            {assignment.rubric_id
              ? `${assignment.name} ${I18n.t('(Already has a rubric)')}`
              : assignment.name}
          </Select.Option>
        ))
      ) : (
        <Select.Option id="empty-option" key="empty-option">
          ---
        </Select.Option>
      )}
    </Select>
  )
}
