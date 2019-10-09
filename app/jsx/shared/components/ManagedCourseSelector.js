/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18n!managed_course_selector'
import React, {useState} from 'react'
import {func} from 'prop-types'

import CanvasAsyncSelect from './CanvasAsyncSelect'
import useManagedCourseSearchApi from '../effects/useManagedCourseSearchApi'
import useDebouncedSearchTerm from '../hooks/useDebouncedSearchTerm'

const MINIMUM_SEARCH_LENGTH = 3

ManagedCourseSelector.propTypes = {
  onCourseSelected: func // (course) => {} (see proptypes/course.js)
}

ManagedCourseSelector.defaultProps = {
  onCourseSelected: () => {}
}

function isSearchableTerm(value) {
  return value.length === 0 || value.length >= MINIMUM_SEARCH_LENGTH
}

export default function ManagedCourseSelector({onCourseSelected}) {
  const [courses, setCourses] = useState(null)
  const [error, setError] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const [inputValue, setInputValue] = useState('')
  const [selectedCourse, setSelectedCourse] = useState(null)
  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    isSearchableTerm
  })

  const searchParams = searchTerm.length === 0 ? {} : {term: searchTerm}
  useManagedCourseSearchApi({
    success: setCourses,
    error: setError,
    loading: setIsLoading,
    params: searchParams
  })

  const handleCourseSelected = (ev, id) => {
    if (courses === null) return
    const course = courses.find(c => c.id === id)
    if (!course) return

    setInputValue(course.name)
    setSelectedCourse(course)
    onCourseSelected(course)
  }

  const handleInputChanged = ev => {
    setInputValue(ev.target.value)
    setSearchTerm(ev.target.value)
    if (selectedCourse !== null) onCourseSelected(null)
    setSelectedCourse(null)
  }

  // If there's an error, throw it to an ErrorBoundary
  if (error !== null) throw error

  const searchableInput = isSearchableTerm(inputValue)
  const noOptionsLabel = searchableInput
    ? I18n.t('No Results')
    : I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH})
  const courseOptions =
    courses === null || !searchableInput
      ? null
      : courses.map(course => (
          <CanvasAsyncSelect.Option key={course.id} id={course.id}>
            {course.name}
          </CanvasAsyncSelect.Option>
        ))

  const selectProps = {
    options: courseOptions,
    isLoading: isLoading || searchTermIsPending,
    inputValue,
    selectedOptionId: selectedCourse ? selectedCourse.id : null,
    assistiveText: I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH}),
    renderLabel: I18n.t('Select a Course'),
    placeholder: I18n.t('Begin typing to search'),
    noOptionsLabel,
    onInputChange: handleInputChanged,
    onOptionSelected: handleCourseSelected
  }
  return <CanvasAsyncSelect {...selectProps}>{courseOptions}</CanvasAsyncSelect>
}
