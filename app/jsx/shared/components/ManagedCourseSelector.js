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
import {useDebouncedCallback} from 'use-debounce'
import _ from 'lodash'

import CanvasAsyncSelect from './CanvasAsyncSelect'
import useManagedCourseSearchApi from '../effects/useManagedCourseSearchApi'

const MINIMUM_SEARCH_LENGTH = 3
const TYPING_DEBOUNCE_TIMEOUT = 750

ManagedCourseSelector.propTypes = {
  onCourseSelected: func // (course) => {} (see proptypes/course.js)
}

ManagedCourseSelector.defaultProps = {
  onCourseSelected: () => {}
}

export default function ManagedCourseSelector({onCourseSelected}) {
  const [courses, setCourses] = useState(null)
  const [error, setError] = useState(null)
  const [inputValue, setInputValue] = useState('')
  const [selectedCourse, setSelectedCourse] = useState(null)
  const [searchParams, rawSetSearchParams] = useState({})

  // We don't want to search immediately after each keystroke, so debounce
  // setting the search parameters.
  const [setSearchParams] = useDebouncedCallback(newSearchParams => {
    // New searches only happen if searchParams actually changes. We only want
    // to clear courses if a new search is actually going to happen to
    // repopulate them.
    if (!_.isEqual(searchParams, newSearchParams)) {
      setCourses(null)
      rawSetSearchParams(newSearchParams)
    }
  }, TYPING_DEBOUNCE_TIMEOUT)

  useManagedCourseSearchApi({
    success: setCourses,
    error: setError,
    params: searchParams
  })
  const searchableInputValue = value => value.length === 0 || value.length >= MINIMUM_SEARCH_LENGTH
  const searchableInput = searchableInputValue(inputValue)

  const handleCourseSelected = (ev, id) => {
    if (courses === null) return
    const course = courses.find(c => c.id === id)
    if (!course) return

    setInputValue(course.name)
    setSelectedCourse(course)
    onCourseSelected(course)
  }

  const handleInputChanged = ev => {
    if (selectedCourse !== null) onCourseSelected(null)
    setSelectedCourse(null)
    setInputValue(ev.target.value)
    const newSearchParams = ev.target.value.length ? {term: ev.target.value} : {}
    setSearchParams(newSearchParams)
  }

  // If there's an error, throw it to an ErrorBoundary
  if (error !== null) throw error

  const isLoading = searchableInput && courses === null
  const noOptionsLabel = searchableInput
    ? I18n.t('No Results')
    : I18n.t('Type at least 3 characters to search.')
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
    isLoading,
    inputValue,
    assistiveText: I18n.t('Type at least 3 characters to search.'),
    renderLabel: I18n.t('Select a Course'),
    placeholder: I18n.t('Begin typing to search'),
    noOptionsLabel,
    onInputChange: handleInputChanged,
    onOptionSelected: handleCourseSelected
  }
  return <CanvasAsyncSelect {...selectProps}>{courseOptions}</CanvasAsyncSelect>
}
