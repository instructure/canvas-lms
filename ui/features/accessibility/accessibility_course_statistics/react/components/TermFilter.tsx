/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useState, useRef, useMemo, useEffect} from 'react'
import {Select} from '@instructure/ui-select'
import {Spinner} from '@instructure/ui-spinner'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useTerms} from '../../hooks/useTerms'

const I18n = createI18nScope('accessibility_course_statistics')

const NO_OPTIONS_ID = '___no_options___'

interface TermOption {
  id: string
  value: string
  label: string
}

type GroupedOptions = Record<string, TermOption[]>

interface TermFilterProps {
  accountId: string
  value: string
  onChange: (termId: string) => void
}

export const TermFilter: React.FC<TermFilterProps> = ({accountId, value, onChange}) => {
  const {activeTerms, futureTerms, pastTerms, isLoading} = useTerms(accountId)
  const [inputValue, setInputValue] = useState('')
  const [filterText, setFilterText] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string | null>(null)
  const [announcement, setAnnouncement] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement | null>(null)

  const allOptions: GroupedOptions = useMemo(() => {
    const groups: GroupedOptions = {
      [I18n.t('Show courses from')]: [{id: 'all-terms', value: '', label: I18n.t('All terms')}],
    }
    if (activeTerms.length > 0) {
      groups[I18n.t('Active Terms')] = activeTerms.map(t => ({
        id: t.id,
        value: t.id,
        label: t.name,
      }))
    }
    if (futureTerms.length > 0) {
      groups[I18n.t('Future Terms')] = futureTerms.map(t => ({
        id: t.id,
        value: t.id,
        label: t.name,
      }))
    }
    if (pastTerms.length > 0) {
      groups[I18n.t('Past Terms')] = pastTerms.map(t => ({
        id: t.id,
        value: t.id,
        label: t.name,
      }))
    }
    return groups
  }, [activeTerms, futureTerms, pastTerms])

  const displayedOptions = useMemo(() => {
    if (!filterText) return allOptions
    const filtered: GroupedOptions = {}
    Object.keys(allOptions).forEach(key => {
      filtered[key] = allOptions[key].filter(o =>
        o.label.toLowerCase().includes(filterText.toLowerCase()),
      )
    })
    return Object.keys(filtered)
      .filter(k => filtered[k].length > 0)
      .reduce<GroupedOptions>((acc, k) => ({...acc, [k]: filtered[k]}), {})
  }, [filterText, allOptions])

  useEffect(() => {
    if (!value) {
      if (selectedOptionId !== 'all-terms') {
        setInputValue('')
        setSelectedOptionId(null)
      }
      return
    }
    const option = Object.values(allOptions)
      .flat()
      .find(o => o.value === value)
    if (option) {
      setInputValue(option.label)
      setSelectedOptionId(option.id)
    }
  }, [value, allOptions])

  const getOptionById = (id: string): TermOption | undefined =>
    Object.values(allOptions)
      .flat()
      .find(o => o.id === id)

  const focusInput = () => {
    inputRef.current?.blur()
    inputRef.current?.focus()
  }

  const handleShowOptions = (event: React.SyntheticEvent) => {
    setIsShowingOptions(true)
    setHighlightedOptionId(null)

    if (inputValue || selectedOptionId || Object.keys(allOptions).length === 0) return

    if ('key' in event) {
      const key = (event as React.KeyboardEvent).key
      if (key === 'ArrowDown') {
        const first = Object.values(allOptions)[0]?.[0]?.id
        if (first) handleHighlightOption(event, {id: first})
      } else if (key === 'ArrowUp') {
        const last = Object.values(allOptions).at(-1)?.at(-1)?.id
        if (last) handleHighlightOption(event, {id: last})
      }
    }
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHighlightOption = (_event: React.SyntheticEvent, {id}: {id?: string}) => {
    if (!id) return
    const option = getOptionById(id)
    if (!option) return
    setTimeout(() => setAnnouncement(option.label), 0)
    setHighlightedOptionId(id)
  }

  const handleSelectOption = (_event: React.SyntheticEvent, {id}: {id?: string}) => {
    if (!id) return
    const option = getOptionById(id)
    if (!option) return
    focusInput()
    setSelectedOptionId(id)
    setInputValue(option.label)
    setFilterText('')
    setIsShowingOptions(false)
    setAnnouncement(option.label)
    onChange(option.value)
  }

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const val = event.target.value
    setInputValue(val)
    setFilterText(val)
    setIsShowingOptions(true)
    setHighlightedOptionId(null)
  }

  const renderChildren = () => {
    if (isLoading) {
      return (
        <Select.Option id={NO_OPTIONS_ID} isDisabled>
          <Spinner renderTitle={I18n.t('Loading terms...')} size="small" />
        </Select.Option>
      )
    }

    if (Object.keys(displayedOptions).length === 0) {
      return (
        <Select.Option id={NO_OPTIONS_ID} isDisabled>
          {I18n.t('No matches')}
        </Select.Option>
      )
    }

    return Object.keys(displayedOptions).map(key => (
      <Select.Group key={key} renderLabel={key}>
        {displayedOptions[key].map(option => (
          <Select.Option
            key={option.id}
            id={option.id}
            isHighlighted={option.id === highlightedOptionId}
            isSelected={option.id === selectedOptionId}
          >
            {option.label}
          </Select.Option>
        ))}
      </Select.Group>
    ))
  }

  return (
    <div>
      <Select
        renderLabel={<ScreenReaderContent>{I18n.t('Filter by term')}</ScreenReaderContent>}
        placeholder={I18n.t('Filter by term')}
        assistiveText={I18n.t('Type or use arrow keys to navigate options.')}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        onBlur={handleBlur}
        onInputChange={handleInputChange}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
        inputRef={(el: HTMLInputElement | null) => {
          inputRef.current = el
        }}
      >
        {renderChildren()}
      </Select>
      {!!(window as Window & {safari?: unknown}).safari && (
        <ScreenReaderContent>
          <span role="alert" aria-live="assertive">
            {announcement}
          </span>
        </ScreenReaderContent>
      )}
    </div>
  )
}
