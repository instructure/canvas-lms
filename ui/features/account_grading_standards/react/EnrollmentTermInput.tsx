/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React, {useState, useRef} from 'react'
import {groupBy, isDate} from 'es-toolkit/compat'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import type {EnrollmentTerm} from './types'

const I18n = createI18nScope('EnrollmentTermInput')

type TagType = 'active' | 'undated' | 'future' | 'past'

interface EnrollmentTermInputProps {
  enrollmentTerms: EnrollmentTerm[]
  setSelectedEnrollmentTermIDs: (termIDs: string[]) => void
  selectedIDs: string[]
}

const groupByTagType = function (options: EnrollmentTerm[]): Record<TagType, EnrollmentTerm[]> {
  const now = new Date()
  const grouped = groupBy(options, option => {
    const noStartDate = !isDate(option.startAt)
    const noEndDate = !isDate(option.endAt)
    const started = !!option.startAt && option.startAt < now
    const ended = !!option.endAt && option.endAt < now

    if ((started && !ended) || (started && noEndDate) || (!ended && noStartDate)) {
      return 'active'
    } else if (!started) {
      return 'future'
    } else if (ended) {
      return 'past'
    }
    return 'undated'
  }) as Partial<Record<TagType, EnrollmentTerm[]>>

  return {
    active: grouped.active ?? [],
    undated: grouped.undated ?? [],
    future: grouped.future ?? [],
    past: grouped.past ?? [],
  }
}

const EnrollmentTermInput = ({
  enrollmentTerms,
  setSelectedEnrollmentTermIDs,
  selectedIDs,
}: EnrollmentTermInputProps) => {
  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  // use later for proper use of <Alert> alongside <Select>
  const [_announcement, setAnnouncement] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement | null>(null)

  const handleChange = (termIDs: string[]) => {
    setSelectedEnrollmentTermIDs(termIDs)
  }

  const selectableTerms = () => {
    const unselectedTerms = enrollmentTerms.filter(term => !selectedIDs.includes(term.id))
    if (!inputValue) return unselectedTerms

    return unselectedTerms.filter(term =>
      (term.displayName ?? term.name).toLowerCase().includes(inputValue.toLowerCase()),
    )
  }

  const filteredTagsForType = (type: TagType) => {
    const groupedTags = groupByTagType(selectableTerms())
    return groupedTags[type]
  }

  const headerText: Record<TagType | 'none', string> = {
    active: I18n.t('Active'),
    undated: I18n.t('Undated'),
    future: I18n.t('Future'),
    past: I18n.t('Past'),
    none: I18n.t('No unassigned terms'),
  }

  const getOptionsByType = (type: TagType) => {
    const terms = filteredTagsForType(type)
    if (terms.length === 0) return []

    return [
      <Select.Group key={`group-${type}`} renderLabel={headerText[type]}>
        {terms.map(term => (
          <Select.Option
            id={term.id}
            key={term.id}
            isHighlighted={term.id === highlightedOptionId}
            value={term.id}
            data-testid={`enrollment-term-option-${term.id}`}
          >
            {term.displayName ?? term.name}
          </Select.Option>
        ))}
      </Select.Group>,
    ]
  }

  const getAllOptions = () => {
    const terms = selectableTerms()
    if (terms.length === 0) {
      return [
        <Select.Option id="none" key="none" data-testid="enrollment-term-no-options">
          {headerText.none}
        </Select.Option>,
      ]
    }

    return [
      ...getOptionsByType('active'),
      ...getOptionsByType('undated'),
      ...getOptionsByType('future'),
      ...getOptionsByType('past'),
    ]
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    setIsShowingOptions(false)
    setInputValue('')
  }

  const handleHighlightOption = (_event: unknown, {id}: {id?: string}) => {
    setHighlightedOptionId(id ?? null)
  }

  const handleSelectOption = (_event: unknown, {id}: {id?: string}) => {
    if (!id || id === 'none') return

    const newSelectedIds = [...selectedIDs]
    if (!newSelectedIds.includes(id)) {
      newSelectedIds.push(id)
    }
    handleChange(newSelectedIds)
    setHighlightedOptionId(null)
    setInputValue('')
    setIsShowingOptions(false)

    const term = enrollmentTerms.find(term_ => term_.id === id)
    if (term) {
      setAnnouncement(`${term.displayName ?? term.name} selected`)
    }
  }

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value
    setInputValue(value)
  }

  const dismissTag = (e: React.SyntheticEvent, termId: string) => {
    e.stopPropagation()
    e.preventDefault()
    const newSelectedIds = selectedIDs.filter(id => id !== termId)
    handleChange(newSelectedIds)
    const term = enrollmentTerms.find(term_ => term_.id === termId)
    if (term) {
      setAnnouncement(`${term.displayName ?? term.name} removed`)
    }
    inputRef.current?.focus()
  }

  const renderTags = () =>
    selectedIDs.map((id, index) => {
      const term = enrollmentTerms.find(term_ => term_.id === id)
      if (!term) return null

      return (
        <Tag
          dismissible={true}
          key={id}
          data-testid={`enrollment-term-tag-${id}`}
          text={
            <AccessibleContent alt={`Remove ${term.displayName ?? term.name}`}>
              {term.displayName ?? term.name}
            </AccessibleContent>
          }
          margin={index > 0 ? 'xxx-small xx-small xxx-small 0' : '0 xx-small 0 0'}
          onClick={e => dismissTag(e, id)}
        />
      )
    })

  return (
    <View as="div" className="ic-Form-control">
      <Select
        data-testid="enrollment-term-select"
        renderLabel={I18n.t('Attach terms')}
        assistiveText={I18n.t(
          'Type or use arrow keys to navigate options. Multiple selections allowed.',
        )}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        inputRef={el => {
          inputRef.current = (el as HTMLInputElement | null) ?? null
        }}
        onInputChange={handleInputChange}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
        renderBeforeInput={selectedIDs.length > 0 ? renderTags() : null}
      >
        {getAllOptions()}
      </Select>
    </View>
  )
}

export default EnrollmentTermInput
