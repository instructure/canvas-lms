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
import PropTypes from 'prop-types'
import {groupBy, isDate} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('EnrollmentTermInput')

const groupByTagType = function (options) {
  const now = new Date()
  return groupBy(options, option => {
    const noStartDate = !isDate(option.startAt)
    const noEndDate = !isDate(option.endAt)
    const started = option.startAt < now
    const ended = option.endAt < now

    if ((started && !ended) || (started && noEndDate) || (!ended && noStartDate)) {
      return 'active'
    } else if (!started) {
      return 'future'
    } else if (ended) {
      return 'past'
    }
    return 'undated'
  })
}

const EnrollmentTermInput = ({enrollmentTerms, setSelectedEnrollmentTermIDs, selectedIDs}) => {
  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)
  // use later for proper use of <Alert> alongside <Select>
  const [_announcement, setAnnouncement] = useState(null)
  const inputRef = useRef(null)

  const handleChange = termIDs => {
    setSelectedEnrollmentTermIDs(termIDs)
  }

  const selectableTerms = () => {
    const unselectedTerms = enrollmentTerms.filter(term => !selectedIDs.includes(term.id))
    if (!inputValue) return unselectedTerms

    return unselectedTerms.filter(term =>
      term.displayName.toLowerCase().includes(inputValue.toLowerCase()),
    )
  }

  const filteredTagsForType = type => {
    const groupedTags = groupByTagType(selectableTerms())
    return (groupedTags && groupedTags[type]) || []
  }

  const headerText = {
    active: I18n.t('Active'),
    undated: I18n.t('Undated'),
    future: I18n.t('Future'),
    past: I18n.t('Past'),
    none: I18n.t('No unassigned terms'),
  }

  const getOptionsByType = type => {
    const terms = filteredTagsForType(type)
    if (terms.length === 0) return []

    const options = [
      <Select.Group key={`group-${type}`} renderLabel={headerText[type]}>
        {terms.map(term => (
          <Select.Option
            id={term.id}
            key={term.id}
            isHighlighted={term.id === highlightedOptionId}
            value={term.id}
            data-testid={`enrollment-term-option-${term.id}`}
          >
            {term.displayName}
          </Select.Option>
        ))}
      </Select.Group>,
    ]

    return options
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

  const handleHighlightOption = (_event, {id}) => {
    setHighlightedOptionId(id)
  }

  const handleSelectOption = (_event, {id}) => {
    const newSelectedIds = [...selectedIDs]
    if (!newSelectedIds.includes(id)) {
      newSelectedIds.push(id)
    }
    handleChange(newSelectedIds)
    setHighlightedOptionId(null)
    setInputValue('')
    setIsShowingOptions(false)
    const term = enrollmentTerms.find(term_ => term_.id === id)
    setAnnouncement(`${term.displayName} selected`)
  }

  const handleInputChange = event => {
    const value = event.target.value
    setInputValue(value)
  }

  const handleKeyDown = event => {
    if (event.keyCode === 8 && inputValue === '' && selectedIDs.length > 0) {
      const newSelectedIds = selectedIDs.slice(0, -1)
      handleChange(newSelectedIds)
    }
  }

  const dismissTag = (e, termId) => {
    e.stopPropagation()
    e.preventDefault()
    const newSelectedIds = selectedIDs.filter(id => id !== termId)
    handleChange(newSelectedIds)
    const term = enrollmentTerms.find(term_ => term_.id === termId)
    setAnnouncement(`${term.displayName} removed`)
    inputRef.current?.focus()
  }

  const renderTags = () => {
    return selectedIDs.map((id, index) => {
      const term = enrollmentTerms.find(term_ => term_.id === id)
      return (
        <Tag
          dismissible={true}
          key={id}
          data-testid={`enrollment-term-tag-${id}`}
          text={
            <AccessibleContent alt={`Remove ${term.displayName}`}>
              {term.displayName}
            </AccessibleContent>
          }
          margin={index > 0 ? 'xxx-small xx-small xxx-small 0' : '0 xx-small 0 0'}
          onClick={e => dismissTag(e, id)}
        />
      )
    })
  }

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
        inputRef={el => (inputRef.current = el)}
        onInputChange={handleInputChange}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
        onKeyDown={handleKeyDown}
        renderBeforeInput={selectedIDs.length > 0 ? renderTags() : null}
      >
        {getAllOptions()}
      </Select>
    </View>
  )
}

EnrollmentTermInput.propTypes = {
  enrollmentTerms: PropTypes.array.isRequired,
  setSelectedEnrollmentTermIDs: PropTypes.func.isRequired,
  selectedIDs: PropTypes.array.isRequired,
}

export default EnrollmentTermInput
