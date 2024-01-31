// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {IconAddLine} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import {Text} from '@instructure/ui-text'
import useFetchApi from '@canvas/use-fetch-api-hook'
import type {SkillData} from '../types'
import {stringToId} from './utils'
import AddSkillModal from './AddSkillModal'
import SkillTag from './SkillTag'

interface SkillSelectProps {
  label: string
  subLabel?: string
  objectSkills: SkillData[]
  selectedSkillIds: string[]
  onSelect: (skills: SkillData[]) => void
}

// this is a tweaked copy of the multi-select example from the instui Select docs
const SkillSelect = ({
  label,
  subLabel,
  objectSkills,
  selectedSkillIds,
  onSelect,
}: SkillSelectProps) => {
  const [options, setOptions] = useState([])
  const [inputValue, setInputValue] = useState('')
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOptionId, setSelectedOptionId] = useState<string[]>(selectedSkillIds)
  const [filteredOptions, setFilteredOptions] = useState([])
  const [announcement, setAnnouncement] = useState<string | null>(null)
  const [addSkillOption] = useState({id: 'add-skill-option', label: 'Add skill or tool'})
  const [showAddSkillModal, setShowAddSkillModal] = useState(false)
  const [valueUpdated, setValueUpdated] = useState(false)
  const inputRef = useRef(null)

  useFetchApi({
    path: `/users/${ENV.current_user.id}/passport/data/skills`,
    success: useCallback(
      (allSkills: SkillData[]) => {
        const opts = allSkills.map(skill => ({
          id: stringToId(skill.name),
          label: skill.name,
          skill,
        }))
        // add portfolio skills to options
        objectSkills.forEach(skill => {
          const id = stringToId(skill.name)
          if (!opts.find(opt => opt.id === id)) {
            opts.push({id, label: skill.name, skill})
          }
        })
        setOptions(opts)
        setFilteredOptions(opts)
      },
      // eslint-disable-next-line react-hooks/exhaustive-deps
      []
    ),
  })

  const getOptionById = useCallback(
    (queryId: string) => {
      if (queryId === 'add-skill-option') {
        return {id: queryId, label: 'Add skill or tool'}
      }
      return options.find(({id}) => id === queryId)
    },
    [options]
  )

  useEffect(() => {
    if (valueUpdated) {
      setValueUpdated(false)
      const newSelectedOptions = selectedOptionId.map(id => getOptionById(id).skill)
      onSelect(newSelectedOptions)
    }
  }, [getOptionById, onSelect, selectedOptionId, valueUpdated])

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
          const option = getOptionById(newOptions[0].id).label
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
      if (inputValue === getOptionById(highlightedOptionId).label) {
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
      if (option.id === addSkillOption.id) {
        setShowAddSkillModal(true)
        return
      }
      const newSelectedOptionIds = [...selectedOptionId, id]
      setSelectedOptionId(newSelectedOptionIds)
      setHighlightedOptionId(null)
      setFilteredOptions(filterOptions(''))
      setInputValue('')
      setIsShowingOptions(false)
      setAnnouncement(`${option.label} selected. List collapsed.`)
      setValueUpdated(true)
    },
    [addSkillOption.id, filterOptions, getOptionById, selectedOptionId]
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

  const handleCloseAddSkillModal = useCallback(() => {
    setShowAddSkillModal(false)
  }, [])

  const handleAddSkill = useCallback(
    (newSkill: SkillData) => {
      setShowAddSkillModal(false)
      setOptions([
        ...options,
        {id: stringToId(newSkill.name), label: newSkill.name, skill: newSkill},
      ])
      const newSelectedOptionIds = [...selectedOptionId, stringToId(newSkill.name)]
      setSelectedOptionId(newSelectedOptionIds)
      setFilteredOptions(filterOptions(''))
      setValueUpdated(true)
    },
    [filterOptions, options, selectedOptionId]
  )

  // remove a selected option tag
  const dismissTag = (e, tag) => {
    // prevent closing of list
    e.stopPropagation()
    e.preventDefault()

    const newSelection = selectedOptionId.filter(id => id !== tag)
    setSelectedOptionId(newSelection)
    setHighlightedOptionId(null)
    inputRef.current.focus()
    setValueUpdated(true)
  }

  const renderTags = () => {
    return selectedOptionId.map((id, index) => {
      const opt = getOptionById(id)
      if (!opt) return null
      const s = opt.skill
      delete s.url
      return (
        <SkillTag
          key={id}
          id={id}
          dismissable={true}
          skill={s}
          margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
          onClick={e => dismissTag(e, id)}
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
    opts.push(
      <Select.Option
        id={addSkillOption.id}
        key={addSkillOption.id}
        isHighlighted={addSkillOption.id === highlightedOptionId}
        renderBeforeLabel={<IconAddLine />}
      >
        {addSkillOption.label}
      </Select.Option>
    )
    return opts
  }

  return (
    <div>
      <Select
        renderLabel={
          <div>
            <Text as="div" weight="bold" lineHeight="double">
              {label}
            </Text>
            <Text as="div" weight="normal">
              {subLabel}
            </Text>
          </div>
        }
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
      <AddSkillModal
        open={showAddSkillModal}
        onDismiss={handleCloseAddSkillModal}
        onAddSkill={handleAddSkill}
      />
    </div>
  )
}

export default SkillSelect
