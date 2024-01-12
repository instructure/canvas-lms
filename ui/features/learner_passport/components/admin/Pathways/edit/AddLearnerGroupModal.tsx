// @ts-nocheck
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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'

import type {LearnerGroupType} from '../../../types'

type SelectOption = {
  id: string
  label: string
  group: LearnerGroupType
}

type AddLearnerGroupModalProps = {
  allLearnerGroups: LearnerGroupType[]
  open: boolean
  selectedGroupIds: string[]
  onClose: () => void
  onSave: (groupIds: string[]) => void
}

const AddLearnerGroupModal = ({
  allLearnerGroups,
  open,
  selectedGroupIds,
  onClose,
  onSave,
}: AddLearnerGroupModalProps) => {
  const [options, setOptions] = useState<SelectOption[]>([])
  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string[]>(selectedGroupIds)
  const [filteredOptions, setFilteredOptions] = useState<SelectOption[]>([])
  const [announcement, setAnnouncement] = useState<string | null>(null)
  // const [valueUpdated, setValueUpdated] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  const handleSave = useCallback(() => {
    onSave(selectedOptionId)
  }, [onSave, selectedOptionId])

  useEffect(() => {
    const opts = allLearnerGroups.map(group => ({
      id: group.id,
      label: group.name,
      group,
    }))
    setOptions(opts)
    setFilteredOptions(opts)
  }, [allLearnerGroups])

  useEffect(() => {
    setSelectedOptionId(selectedGroupIds)
  }, [selectedGroupIds])

  const getOptionById = useCallback(
    (queryId: string) => {
      return options.find(({id}) => id === queryId)
    },
    [options]
  )

  // useEffect(() => {
  //   if (valueUpdated) {
  //     setValueUpdated(false)
  //     const newSelectedOptions = selectedOptionId.map(id => getOptionById(id).skill)
  //     onSelect(newSelectedOptions)
  //   }
  // }, [getOptionById, onSelect, selectedOptionId, valueUpdated])

  const getOptionsChangedMessage = useCallback(
    newOptions => {
      let message =
        newOptions.length !== filteredOptions.length
          ? `${newOptions.length} options available.` // options changed, announce new total
          : null // options haven't changed, don't announce
      if (message && newOptions.length > 0) {
        // options still available
        if (highlightedOptionId !== newOptions[0].id) {
          // highlighted option hasn't been announced
          const option = getOptionById(newOptions[0].id)?.label
          message = `${option}. ${message}`
        }
      }
      return message
    },
    [filteredOptions.length, getOptionById, highlightedOptionId]
  )

  const filterOptions = useCallback(
    value => {
      return options.filter(option => option.label.toLowerCase().startsWith(value.toLowerCase()))
    },
    [options]
  )

  const matchValue = useCallback(() => {
    // an option matching user input exists
    if (filteredOptions.length === 1) {
      const onlyOption = filteredOptions[0]
      // automatically select the matching option
      if (onlyOption.label.toLowerCase() === inputValue.toLowerCase()) {
        return {
          inputValue: '',
          selectedOptionId: [...selectedOptionId, onlyOption.id],
          filteredOptions: filterOptions(''),
        }
      }
    }
    // input value is from highlighted option, not user input
    // clear input, reset options
    if (highlightedOptionId) {
      if (inputValue === getOptionById(highlightedOptionId)?.label) {
        return {
          inputValue: '',
          filteredOptions: filterOptions(''),
        }
      }
    }
  }, [
    filterOptions,
    filteredOptions,
    getOptionById,
    highlightedOptionId,
    inputValue,
    selectedOptionId,
  ])

  const handleShowOptions = useCallback(() => {
    setIsShowingOptions(true)
  }, [])

  const handleHideOptions = useCallback(() => {
    setIsShowingOptions(false)
    const matches = matchValue()
    if (matches) {
      if ('inputValue' in matches) setInputValue(matches.inputValue)
      if ('selectedOptionId' in matches) setSelectedOptionId(matches.selectedOptionId)
      if ('filteredOptions' in matches) setFilteredOptions(matches.filteredOptions)
    }
  }, [matchValue])

  const handleBlur = useCallback(() => {
    setHighlightedOptionId(null)
  }, [])

  const handleHighlightOption = useCallback(
    (event, {id}) => {
      event.persist()
      const option = getOptionById(id)
      if (!option) return
      setHighlightedOptionId(id)
      if (id !== 'add-skill-option') {
        setInputValue(event.type === 'keydown' ? option.label : inputValue)
      }
      setAnnouncement(option.label)
    },
    [getOptionById, inputValue]
  )

  const handleSelectOption = useCallback(
    (event, {id}) => {
      const option = getOptionById(id)
      if (!option) return

      const newSelectedOptionIds = [...selectedOptionId, id]
      setSelectedOptionId(newSelectedOptionIds)
      setHighlightedOptionId(null)
      setFilteredOptions(filterOptions(''))
      setInputValue('')
      setIsShowingOptions(false)
      setAnnouncement(`${option.label} selected. List collapsed.`)
      // setValueUpdated(true)
    },
    [filterOptions, getOptionById, selectedOptionId]
  )

  const handleInputChange = useCallback(
    event => {
      const value = event.target.value
      const newOptions = filterOptions(value)
      setInputValue(value)
      setFilteredOptions(newOptions)
      setHighlightedOptionId(newOptions.length > 0 ? newOptions[0].id : null)
      setIsShowingOptions(true)
      setAnnouncement(getOptionsChangedMessage(newOptions))
    },
    [filterOptions, getOptionsChangedMessage]
  )

  const handleKeyDown = useCallback(
    event => {
      if (event.keyCode === 8) {
        // when backspace key is pressed
        if (inputValue === '' && selectedOptionId.length > 0) {
          // remove last selected option, if input has no entered text
          setHighlightedOptionId(null)
          setSelectedOptionId(selectedOptionId.slice(0, -1))
        }
      }
    },
    [inputValue, selectedOptionId]
  )

  const dismissTag = (e: React.Synthe, tag) => {
    // prevent closing of list
    e.stopPropagation()
    e.preventDefault()

    const newSelection = selectedOptionId.filter(id => id !== tag)
    setSelectedOptionId(newSelection)
    setHighlightedOptionId(null)
    inputRef.current?.focus()
    // setValueUpdated(true)
  }

  const renderTags = () => {
    return selectedOptionId.map((id, index) => {
      const opt = getOptionById(id)
      if (!opt) return null
      const g = opt.group
      return (
        <Tag
          key={g.id}
          id={g.id}
          dismissible={true}
          margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
          text={g.name}
          onClick={e => dismissTag(e, id)}
          themeOverride={{maxWidth: '100%'}}
        />
      )
    })
  }

  const renderOptions = () => {
    const opts = []
    if (filteredOptions.length > 0) {
      filteredOptions.forEach(option => {
        if (selectedOptionId.indexOf(option.id) === -1) {
          opts.push(
            <Select.Option
              id={option.id}
              key={option.id}
              isHighlighted={option.id === highlightedOptionId}
            >
              {option.label}
            </Select.Option>
          )
        }
      })
    }
    return opts
  }

  return (
    <Modal
      open={open}
      onDismiss={onClose}
      label="Add Learner Group"
      size="large"
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton placement="end" offset="medium" onClick={onClose} screenReaderLabel="Close" />
        <Heading>Add Learner Group</Heading>
      </Modal.Header>
      <Modal.Body padding="medium">
        <Select
          renderLabel="Select a group from Canvas to add to this pathway"
          assistiveText="Type or use arrow keys to navigate options. Multiple selections allowed."
          inputValue={inputValue}
          isShowingOptions={isShowingOptions}
          inputRef={el => (inputRef.current = el)}
          onBlur={handleBlur}
          onInputChange={handleInputChange}
          onRequestShowOptions={handleShowOptions}
          onRequestHideOptions={handleHideOptions}
          onRequestHighlightOption={handleHighlightOption}
          onRequestSelectOption={handleSelectOption}
          onKeyDown={handleKeyDown}
          renderBeforeInput={selectedOptionId.length > 0 ? renderTags() : null}
        >
          {renderOptions()}
        </Select>
        <Alert
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          liveRegionPoliteness="assertive"
          screenReaderOnly={true}
        >
          {announcement}
        </Alert>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose}>Cancel</Button>
        <Button onClick={handleSave} color="primary" margin="0 0 0 x-small">
          Save
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default AddLearnerGroupModal
