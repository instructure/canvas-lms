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

import React, { useState, useEffect, useCallback, useRef } from 'react'
import { Select } from '@instructure/ui-select'
import { IconSearchLine } from '@instructure/ui-icons'
import { Spinner } from '@instructure/ui-spinner'
import type { CourseOption } from '../types'
import {FormMessage} from '@instructure/ui-form-field'
import { useScope as createI18nScope } from '@canvas/i18n'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('content_migrations_redesign')

type AsyncCourseSearchSelectProps = {
  getCourseOptions: (searchTerm: string) => Promise<CourseOption[]>
  interaction: "disabled" | "enabled" | "readonly"
  selectedCourse: CourseOption | null
  onSelectCourse: (course: CourseOption | null) => void
  messages?: FormMessage[]
  inputRef?: (ref: HTMLInputElement | null) => void
}

const getCourseOptionDescription = (option: CourseOption): string | null => {
  return option.term ? I18n.t('Term: %{termName}', {termName: option.term}) : null
}

const AsyncCourseSearchSelect = ({
  getCourseOptions,
  interaction,
  selectedCourse,
  onSelectCourse,
  messages = [],
  inputRef
}: AsyncCourseSearchSelectProps) => {
  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string | null>(null)
  const [selectedOptionLabel, setSelectedOptionLabel] = useState('')
  const [filteredOptions, setFilteredOptions] = useState<CourseOption[]>([])

  const timeoutId = useRef<NodeJS.Timeout | null>(null)

  useEffect(() => {
    if (selectedCourse) {
      setSelectedOptionId(selectedCourse.id)
      setSelectedOptionLabel(selectedCourse.label)
      setInputValue(selectedCourse.label)
      setFilteredOptions([selectedCourse])
    }
  }, [selectedCourse])

  const getOptionById = useCallback(
    (id: string) => filteredOptions.find(opt => opt.id === id),
    [filteredOptions]
  )

  const matchValue = () => {
    if (filteredOptions.length === 1) {
      const only = filteredOptions[0]
      if (only.label.toLowerCase() === inputValue.toLowerCase()) {
        setInputValue(only.label)
        setSelectedOptionId(only.id)
        return
      }
    }

    if (inputValue.length === 0) {
      setSelectedOptionId(null)
      setFilteredOptions([])
      return
    }

    if (selectedOptionId) {
      setInputValue(selectedOptionLabel)
    }
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    matchValue()
    if (!filteredOptions.find(o => o.label === inputValue)) {
      onSelectCourse(null)
    }
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHighlight = (e: React.SyntheticEvent, { id }: any) => {
    e.persist()
    const option = getOptionById(id)
    if (!option) return
    setHighlightedOptionId(id)
    setInputValue(e.type === 'keydown' ? option.label : inputValue)
  }

  const handleSelect = (_e: React.SyntheticEvent, { id }: any) => {
    const option = getOptionById(id)
    if (!option) return
    setSelectedOptionId(id)
    setSelectedOptionLabel(option.label)
    setInputValue(option.label)
    setIsShowingOptions(false)
    setFilteredOptions([option])
    onSelectCourse(option)
  }

  const handleInputChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    if (timeoutId.current) clearTimeout(timeoutId.current)
    setInputValue(value)

    if (!value) {
      setIsLoading(false)
      setSelectedOptionId(null)
      setSelectedOptionLabel('')
      setFilteredOptions([])
      setIsShowingOptions(true)
      return
    }
    onSelectCourse(null)
    setIsLoading(true)
    setIsShowingOptions(true)
    setFilteredOptions([])
    setHighlightedOptionId(null)

    timeoutId.current = setTimeout(async () => {
      try {
        const results = await getCourseOptions(value)
        setFilteredOptions(results)
      } catch {
        setFilteredOptions([])
      } finally {
        setIsLoading(false)
      }
    }, 500)
  }

  return (
    <Select
      id="course-copy-select-course"
      data-testid="course-copy-select-course"
      placeholder={I18n.t('Search...')}
      renderLabel={I18n.t('Search for a course')}
      assistiveText={I18n.t('Type to search for a course')}
      inputValue={inputValue}
      isShowingOptions={isShowingOptions}
      onBlur={handleBlur}
      onInputChange={handleInputChange}
      onRequestShowOptions={handleShowOptions}
      onRequestHideOptions={handleHideOptions}
      onRequestSelectOption={handleSelect}
      onRequestHighlightOption={handleHighlight}
      messages={messages}
      inputRef={inputRef}
      renderBeforeInput={<IconSearchLine />}
      interaction={interaction}
    >
      {filteredOptions.length > 0 ? (
        filteredOptions.map(opt => {
          const isHighlighted = opt.id === highlightedOptionId
          return (
            <Select.Option
              key={opt.id}
              id={opt.id}
              isHighlighted={isHighlighted}
              isSelected={opt.id === selectedOptionId}
            >
              {opt.label}
              <Text size="x-small" as="div" color={isHighlighted ? 'secondary-inverse' : 'secondary'}>
                {getCourseOptionDescription(opt)}
              </Text>
            </Select.Option>
          )
        })
      ) : (
        <Select.Option id="empty-option" key="empty-option">
          {isLoading ? (
            <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
          ) : inputValue ? (
            I18n.t('No results')
          ) : (
            I18n.t('Type to search')
          )}
        </Select.Option>
      )}
    </Select>
  )
}

export default AsyncCourseSearchSelect
