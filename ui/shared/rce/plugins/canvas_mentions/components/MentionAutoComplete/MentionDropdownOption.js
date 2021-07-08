/* eslint-disable jsx-a11y/click-events-have-key-events */
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Avatar} from '@instructure/ui-avatar'
import PropTypes from 'prop-types'
import React, {useEffect, useState, useRef} from 'react'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const MentionDropdownOption = props => {
  const [isHover, setHover] = useState(false)
  const optionRef = useRef()

  // Scroll individual item into view when its selected or navigated towards
  useEffect(() => {
    if (props.isSelected) {
      optionRef.current.scrollIntoView({behavior: 'smooth', block: 'center'})
    }
  }, [props.isSelected])

  return (
    <View
      as="div"
      background={isHover || props.isSelected ? 'brand' : null}
      padding="xx-small"
      onMouseEnter={() => {
        setHover(true)
      }}
      onMouseLeave={() => {
        setHover(false)
      }}
    >
      <li
        aria-selected={props.isSelected}
        id={props.id}
        ref={optionRef}
        role="option"
        style={{listStyle: 'none'}}
        onClick={props.onSelect}
      >
        <View as="div">
          <Avatar name={props.name} margin="0 small 0 0" size="x-small" />
          <Text color={isHover ? 'primary-inverse' : null}>{props.name}</Text>
        </View>
      </li>
    </View>
  )
}

export default MentionDropdownOption

MentionDropdownOption.props = {
  /**
   * Sets if selected
   */
  isSelected: PropTypes.bool,
  /**
   * Name to be displayed
   */
  name: PropTypes.string.isRequired,
  /**
   * onSelect callback that accepts a function
   */
  onSelect: PropTypes.string.isRequired
}
