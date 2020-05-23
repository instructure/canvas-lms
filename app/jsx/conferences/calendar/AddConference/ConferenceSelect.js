/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {Img} from '@instructure/ui-img'
import {Select} from '@instructure/ui-select'
import {Text} from '@instructure/ui-text'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!conferences'
import webConferenceType from 'jsx/shared/proptypes/webConferenceType'

function iconFor(conferenceType) {
  const icon = conferenceType?.lti_settings?.icon_url
  return icon ? (
    <PresentationContent>
      <Img src={icon} height="20px" width="20px" />
    </PresentationContent>
  ) : null
}

function nameFor(conferenceType) {
  return conferenceType?.lti_settings?.text || conferenceType?.name
}

function makeId(index) {
  return `id_${index}`
}

function getIndex(id) {
  return parseInt(id.split('_')[1], 10)
}

const ConferenceSelect = ({currentConferenceType, conferenceTypes, onSelectConferenceType}) => {
  const [showingOptions, setShowingOptions] = useState(false)
  const [highlightedIndex, setHighlightedIndex] = useState(null)

  const selectedIndex = currentConferenceType ? conferenceTypes.indexOf(currentConferenceType) : -1

  const onSelect = index => {
    setShowingOptions(false)
    if (index !== selectedIndex) {
      onSelectConferenceType(conferenceTypes[index])
    }
  }

  return (
    <Select
      size="small"
      assistiveText={I18n.t('Use arrow keys to select a conference provider')}
      renderBeforeInput={iconFor(currentConferenceType)}
      renderLabel={
        <ScreenReaderContent>{I18n.t('Select Conference Provider')}</ScreenReaderContent>
      }
      inputValue={nameFor(currentConferenceType) || I18n.t('Add Conferencing')}
      isShowingOptions={showingOptions}
      onBlur={() => setHighlightedIndex(null)}
      onRequestShowOptions={() => setShowingOptions(true)}
      onRequestHideOptions={() => setShowingOptions(false)}
      onRequestHighlightOption={(_e, {id}) => setHighlightedIndex(getIndex(id))}
      onRequestSelectOption={(_e, {id}) => onSelect(getIndex(id))}
    >
      {conferenceTypes.map((conferenceType, index) => {
        const id = makeId(index)
        return (
          <Select.Option
            id={id}
            key={id}
            isHighlighted={index === highlightedIndex}
            isSelected={index === selectedIndex}
          >
            {iconFor(conferenceType)}
            <Text size="small">{nameFor(conferenceType) || I18n.t('Unknown Conference')}</Text>
          </Select.Option>
        )
      })}
    </Select>
  )
}

ConferenceSelect.propTypes = {
  conferenceTypes: PropTypes.arrayOf(webConferenceType).isRequired,
  currentConferenceType: webConferenceType,
  onSelectConferenceType: PropTypes.func.isRequired
}

ConferenceSelect.defaultProps = {
  currentConferenceType: null
}

export default ConferenceSelect
