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
import {useScope} from '@canvas/i18n'

const I18n = useScope('mentions')

const addIgnoreAttributes = node => {
  node.setAttribute('data-ignore-a11y-check', '')
  if (node.tagName !== 'IMG') {
    node.setAttribute('data-ignore-wordcount', 'chars-only')
  }
}

const MentionDropdownOption = props => {
  const [isHover, setHover] = useState(false)
  const optionRef = useRef()

  // Scroll individual item into view when its selected or navigated towards
  useEffect(() => {
    if (
      props.isSelected &&
      optionRef.current &&
      props.menuRef &&
      !props.highlightMouse &&
      props.isInteractive
    ) {
      const menuItemOffsetTop = optionRef.current?.offsetTop
      const menuHeight = props.menuRef.current?.clientHeight
      const itemHeight = optionRef.current?.clientHeight
      props.menuRef.current.scrollTop = menuItemOffsetTop - (menuHeight - itemHeight) / 2
    }
  }, [props.highlightMouse, props.isInteractive, props.isSelected, props.menuRef, props.optionRef])

  return (
    <View
      as="div"
      background={
        (isHover && props.highlightMouse) || (props.isSelected && !props.highlightMouse)
          ? 'brand'
          : null
      }
      elementRef={el => {
        optionRef.current = el
      }}
      padding="xx-small"
      onMouseEnter={() => {
        if (props.highlightMouse) {
          props.onOptionMouseEnter()
          setHover(true)
        }
      }}
      onMouseLeave={() => {
        setHover(false)
      }}
      data-testid="mention-dropdown-item"
    >
      <li
        aria-selected={props.isSelected}
        id={props.id}
        aria-label={I18n.t('Select %{name} to mention', {name: props.name})}
        role="option"
        style={{listStyle: 'none'}}
        onClick={props.onSelect}
      >
        <View as="div">
          <Avatar
            name={props.name}
            margin="0 small 0 0"
            size="x-small"
            elementRef={ref => {
              ref?.childNodes.forEach(addIgnoreAttributes)
            }}
          />
          <Text
            color={
              (isHover && props.highlightMouse) || (props.isSelected && !props.highlightMouse)
                ? 'primary-inverse'
                : null
            }
            data-ignore-a11y-check=""
            data-ignore-wordcount=""
          >
            {props.name}
          </Text>
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
  onSelect: PropTypes.string.isRequired,
  /**
   * Bool to control mouse highlighting
   */
  highlightMouse: PropTypes.bool,
  /**
   * Callback to set focused user
   */
  onOptionMouseEnter: PropTypes.func,
  /**
   * Menu Ref is needed to scroll menu correctly
   */
  menuRef: PropTypes.node,
}
