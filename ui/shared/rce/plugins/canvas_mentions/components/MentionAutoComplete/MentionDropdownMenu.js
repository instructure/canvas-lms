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
import React, {useMemo} from 'react'
import MentionDropdownOption from './MentionDropdownOption'
import {View} from '@instructure/ui-view'

const MentionDropdownMenu = ({onSelect, mentionOptions, show, x, y, selectedUser, popupId}) => {
  // Memoize map of Mention Options
  const menuItems = useMemo(() => {
    return mentionOptions.map(user => {
      return (
        <MentionDropdownOption
          {...user}
          onSelect={() => {
            onSelect(user)
          }}
          isSelected={selectedUser === user.id}
          key={`${popupId}-mention-popup-${user.id}`}
          id={`${popupId}-mention-popup-${user.id}`}
        />
      )
    })
  }, [mentionOptions, onSelect, popupId, selectedUser])

  // Don't show if menu is empty
  if (!show || mentionOptions?.length === 0) {
    return null
  }

  // Convert cords to px
  const xOffset = Math.round(x).toString() + 'px'
  const yOffset = Math.round(y).toString() + 'px'

  return (
    <div
      className="mention-dropdown-menu"
      style={{
        position: 'absolute',
        top: yOffset,
        left: xOffset
      }}
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
      >
        <ul
          aria-label="Mentionable Users"
          id={`${popupId}-mention-popup`}
          role="listbox"
          style={{
            paddingInlineStart: '0px',
            marginBlockStart: '0px',
            marginBlockEnd: '0px'
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
   * Unique popup ID supplied for ARIA support
   */
  popupId: PropTypes.string,
  /**
   * Bool that controls visibility of menu
   */
  show: PropTypes.bool,
  /**
   * X cordinate for menu on screen (in px)
   */
  x: PropTypes.number,
  /**
   * y cordinate for menu on screen (in px)
   */
  y: PropTypes.number,
  /**
   * Callback for selecting an item
   */
  onSelect: PropTypes.func
}
