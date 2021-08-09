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
import React, {useEffect, useRef, useState, useLayoutEffect, useCallback, useMemo} from 'react'
import MentionDropdownMenu from './MentionDropdownMenu'
import PropTypes from 'prop-types'
import getPosition from './getPosition'
import {
  ARIA_ID_TEMPLATES,
  MARKER_ID,
  TRUSTED_MESSAGE_ORIGIN,
  NAVIGATION_MESSAGE,
  INPUT_CHANGE_MESSAGE,
  KEY_NAMES,
  KEY_CODES
} from '../../constants'

const MentionMockUsers = [
  {
    id: 1,
    name: 'Jeffrey Johnson'
  },
  {
    id: 2,
    name: 'Matthew Lemon'
  },
  {
    id: 3,
    name: 'Rob Orton'
  },
  {
    id: 4,
    name: 'Davis Hyer'
  },
  {
    id: 5,
    name: 'Drake Harper'
  },
  {
    id: 6,
    name: 'Omar Soto-Fortuño'
  },
  {
    id: 7,
    name: 'Chawn Neal'
  },
  {
    id: 8,
    name: 'Mauricio Ribeiro'
  },
  {
    id: 9,
    name: 'Caleb Guanzon'
  },
  {
    id: 10,
    name: 'Jason Gillett'
  }
]

const MentionUIManager = ({editor, mentionData, onFocusedUserChange, onSelect}) => {
  // Setup State
  const [menitonCordinates, setMenitonCordinates] = useState(null)
  const [focusedUser, setFocusedUser] = useState()
  const [inputText, setInputText] = useState('')

  // Setup Refs for listener access
  const focusedUserRef = useRef(focusedUser)

  const filteredOptions = useMemo(() => {
    return mentionData?.filter(o => {
      return o.name.toLowerCase().includes(inputText?.toLowerCase().trim())
    })
  }, [inputText, mentionData])

  const getXYPosition = useCallback(() => {
    const responseObj = getPosition(tinyMCE.activeEditor, `#${MARKER_ID}`)
    setMenitonCordinates(responseObj)
  }, [])

  // Navigates highlight of mention
  const navigateFocusedUser = dir => {
    // Return if no options present
    if (filteredOptions.length === 0) {
      return
    }

    // When no user is selected or filterSet doesn't contain focused user
    if (focusedUserRef.current === null || !filteredOptions.includes(focusedUserRef.current)) {
      setFocusedUser(filteredOptions[0])
      return
    }

    const selectedUser = focusedUserRef.current
    const selectedUserIndex = filteredOptions.findIndex(m => m.id === selectedUser.id)

    switch (dir) {
      case 'down':
        setFocusedUser(
          filteredOptions[
            selectedUserIndex + 1 >= filteredOptions.length ? 0 : selectedUserIndex + 1
          ]
        )
        break
      case 'up':
        setFocusedUser(
          filteredOptions[
            selectedUserIndex - 1 < 0 ? filteredOptions.length - 1 : selectedUserIndex - 1
          ]
        )
        break
      default:
        break
    }
  }

  const keyboardEvents = value => {
    switch (value) {
      case KEY_NAMES[KEY_CODES.up]:
        // Up
        navigateFocusedUser('up')
        break
      case KEY_NAMES[KEY_CODES.down]:
        // Down
        navigateFocusedUser('down')
        break
      default:
        break
    }
  }

  const handleInputChange = value => {
    getXYPosition()
    setInputText(value)
  }

  const messageCallback = e => {
    if (e.origin !== TRUSTED_MESSAGE_ORIGIN) {
      return
    }

    const messageType = e.data.messageType
    const value = e.data.value

    switch (messageType) {
      case NAVIGATION_MESSAGE:
        keyboardEvents(value)
        break
      case INPUT_CHANGE_MESSAGE:
        handleInputChange(value)
        break
      default:
        break
    }
  }

  // Make us maintain a focused user when open
  useEffect(() => {
    if (!filteredOptions.includes(focusedUser)) {
      setFocusedUser(filteredOptions[0])
    }
  }, [filteredOptions, focusedUser])

  // Keep Focus User and active decendant always up to date
  useEffect(() => {
    if (focusedUser) {
      onFocusedUserChange({
        ...focusedUser,
        ariaActiveDescendantId: ARIA_ID_TEMPLATES.activeDescendant(editor.id, focusedUser.id)
      })
    } else {
      onFocusedUserChange(null)
    }
    focusedUserRef.current = focusedUser
  }, [editor.id, focusedUser, onFocusedUserChange])

  // Window listeners handler
  useLayoutEffect(() => {
    window.addEventListener('resize', getXYPosition)
    window.addEventListener('scroll', getXYPosition)
    window.addEventListener('message', messageCallback)

    return () => {
      window.removeEventListener('resize', getXYPosition)
      window.removeEventListener('scroll', getXYPosition)
      window.removeEventListener('message', messageCallback)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Set initial positioning
  useEffect(() => {
    getXYPosition()
  }, [getXYPosition])

  return (
    <MentionDropdownMenu
      instanceId={editor.id}
      mentionOptions={filteredOptions}
      show
      coordiantes={menitonCordinates}
      selectedUser={focusedUser?.id}
      onSelect={user => {
        setFocusedUser(user)
        onSelect()
      }}
    />
  )
}

export default MentionUIManager

MentionUIManager.propTypes = {
  mentionData: PropTypes.array,
  rceRef: PropTypes.object,
  onFocusedUserChange: PropTypes.func,
  onExited: PropTypes.func,
  onSelect: PropTypes.func,
  editor: PropTypes.object
}

MentionUIManager.defaultProps = {
  mentionData: MentionMockUsers,
  onFocusedUserChange: () => {},
  onExited: () => {},
  onSelect: () => {}
}
