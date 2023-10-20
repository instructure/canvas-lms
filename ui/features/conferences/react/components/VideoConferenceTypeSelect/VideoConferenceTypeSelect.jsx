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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import PropTypes, {arrayOf} from 'prop-types'

import {Select} from '@instructure/ui-select'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('video_conference')

const VideoConferenceTypeSelect = ({conferenceTypes, onSetConferenceType, isEditing}) => {
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [selectedOptionId, setSelectedOptionId] = useState(conferenceTypes[0].type)
  const [inputValue, setInputValue] = useState(conferenceTypes[0].name)
  const [highlightedOptionId, setHighlightedOptionId] = useState(null)

  const getOptionById = queryId => {
    return conferenceTypes.find(({type}) => type === queryId)
  }

  const handleShowOptions = () => {
    setIsShowingOptions(true)
  }

  const handleHideOptions = () => {
    const option = getOptionById(selectedOptionId)
    setIsShowingOptions(false)
    setHighlightedOptionId(null)
    setInputValue(selectedOptionId ? option?.name : '')
  }

  const handleBlur = () => {
    setHighlightedOptionId(null)
  }

  const handleHighlightOption = (event, {id}) => {
    event.persist()
    const option = getOptionById(id)
    setHighlightedOptionId(id)
    setInputValue(event.type === 'keydown' ? option?.name : inputValue)
  }

  const handleSelectOption = (event, {id}) => {
    const option = getOptionById(id)
    setSelectedOptionId(id)
    setInputValue(option?.name || '')
    setIsShowingOptions(false)
    onSetConferenceType(option.type)
  }

  return (
    <View as="div" margin="medium" data-testid="conference-type-select">
      <Select
        renderLabel={I18n.t('Conference Type')}
        assistiveText={I18n.t('Use arrow keys to navigate options.')}
        inputValue={inputValue}
        isShowingOptions={isShowingOptions}
        onBlur={handleBlur}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
        disabled={isEditing}
      >
        {conferenceTypes.map(option => {
          return (
            <Select.Option
              id={option.type}
              key={option.type}
              isHighlighted={option.type === highlightedOptionId}
              isSelected={option.type === selectedOptionId}
            >
              {option?.name}
            </Select.Option>
          )
        })}
      </Select>
    </View>
  )
}

VideoConferenceTypeSelect.prototype = {
  conferenceTypes: arrayOf(PropTypes.object),
  onSetConferenceType: PropTypes.func,
  isEditing: PropTypes.bool,
}

export default VideoConferenceTypeSelect
