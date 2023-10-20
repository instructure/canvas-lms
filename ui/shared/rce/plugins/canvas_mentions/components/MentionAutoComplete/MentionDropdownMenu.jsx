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
import PropTypes from 'prop-types'
import React, {useMemo, useRef, useState} from 'react'
import MentionDropdownOption from './MentionDropdownOption'
import {View} from '@instructure/ui-view'
import {usePopper} from 'react-popper'
import {ARIA_ID_TEMPLATES} from '../../constants'

const MentionDropdownMenu = ({
  onSelect,
  onMouseEnter,
  mentionOptions,
  coordiantes,
  selectedUser,
  instanceId,
  highlightMouse,
  onOptionMouseEnter,
  isInteractive,
}) => {
  // Hooks & Variables
  const directionality = tinyMCE?.activeEditor?.getParam('directionality')
  const menuRef = useRef(null)

  // Setup Popper
  const virtualReference = useMemo(() => {
    return {
      getBoundingClientRect: () => {
        return coordiantes
      },
    }
  }, [coordiantes])
  const [popperElement, setPopperElement] = useState(null)
  const {styles, attributes} = usePopper(virtualReference, popperElement, {
    placement: directionality === 'rtl' ? 'bottom-end' : 'bottom-start',
    modifiers: [
      {
        name: 'flip',
        options: {
          flipVariations: false,
          fallbackPlacements: ['bottom', 'bottom-end', 'bottom-start'],
        },
      },
    ],
  })

  // Memoize map of Mention Options
  const menuItems = useMemo(() => {
    return mentionOptions.map(user => {
      return (
        <MentionDropdownOption
          {...user}
          onSelect={() => {
            onSelect({
              ...user,
              elementId: ARIA_ID_TEMPLATES.activeDescendant(instanceId, user.id),
            })
          }}
          isSelected={selectedUser === user.id}
          key={user.id}
          id={ARIA_ID_TEMPLATES.activeDescendant(instanceId, user.id)}
          highlightMouse={highlightMouse}
          onOptionMouseEnter={() => {
            onOptionMouseEnter(user)
          }}
          menuRef={menuRef}
          isInteractive={isInteractive}
        />
      )
    })
  }, [
    mentionOptions,
    selectedUser,
    instanceId,
    highlightMouse,
    isInteractive,
    onSelect,
    onOptionMouseEnter,
  ])

  // Don't show if menu is empty
  if (mentionOptions?.length === 0) {
    return null
  }

  return (
    <div
      className="mention-dropdown-menu"
      ref={isInteractive ? setPopperElement : null}
      style={isInteractive ? {...styles.popper, zIndex: 10000} : null}
      onMouseEnter={isInteractive ? onMouseEnter : null}
      {...attributes.popper}
    >
      <View
        as="div"
        background="primary"
        borderWidth="small"
        borderRadius="medium"
        maxHeight="200px"
        maxWidth="400px"
        minWidth="320px"
        overflowY="auto"
        padding="none"
        shadow="above"
        width="auto"
        elementRef={el => {
          menuRef.current = el
        }}
      >
        <ul
          aria-label="Mentionable Users"
          id={ARIA_ID_TEMPLATES.ariaControlTemplate(instanceId)}
          role="listbox"
          style={{
            paddingInlineStart: '0px',
            marginBlockStart: '0px',
            marginBlockEnd: '0px',
            margin: '0',
          }}
        >
          {menuItems}
        </ul>
      </View>
    </div>
  )
}

export default MentionDropdownMenu

MentionDropdownMenu.proptypes = {
  /**
   * Array of optons to be presented to user
   */
  mentionOptions: PropTypes.array,
  /**
   * Unique ID supplied for ARIA support
   */
  instanceId: PropTypes.string,
  /**
   * cordinates for menu on screen
   */
  coordiantes: PropTypes.object,
  /**
   * Callback for selecting an item
   */
  onSelect: PropTypes.func,
  /**
   * ID of selected user
   */
  selectedUser: PropTypes.string,
  /**
   * Event for triggering onMosueOver
   */
  onMouseEnter: PropTypes.func,
  /**
   * Bool to control mouse highlighting
   */
  highlightMouse: PropTypes.bool,
  /**
   * Callback to set user on hover
   */
  onOptionMouseEnter: PropTypes.func,
  /**
   * isInteractive determines if menu will recieve events
   * This is used for the hidden menu offscreen in the RCE
   */
  isInteractive: PropTypes.bool,
}

MentionDropdownMenu.defaultProps = {
  isInteractive: true,
  onSelect: () => {},
}
