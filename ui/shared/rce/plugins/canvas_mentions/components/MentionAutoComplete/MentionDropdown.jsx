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
import MentionDropdownPortal from './MentionDropdownPortal'
import PropTypes from 'prop-types'
import getPosition from './getPosition'
import {
  ARIA_ID_TEMPLATES,
  MARKER_ID,
  TRUSTED_MESSAGE_ORIGIN,
  NAVIGATION_MESSAGE,
  INPUT_CHANGE_MESSAGE,
  KEY_NAMES,
  KEY_CODES,
} from '../../constants'
import {MENTIONABLE_USERS_QUERY} from './graphql/Queries'
import {useQuery} from '@apollo/react-hooks'

const MOUSE_FOCUS_TYPE = 'mouse'
const KEYBOARD_FOCUS_TYPE = 'keyboard'

const MentionUIManager = ({editor, onExited, onFocusedUserChange, rceRef}) => {
  // Setup State
  const [mentionCoordinates, setMentionCoordinates] = useState(null)
  const [focusedUser, setFocusedUser] = useState()
  const [inputText, setInputText] = useState('')
  const [debouncedInputText, setDebouncedInputText] = useState('')
  const [shouldExit, setShouldExit] = useState(false)
  const [noResults, setNoResults] = useState(false)
  const [focusType, setFocusType] = useState(null) // Options are 'keyboard' and 'mouse'

  // Setup Refs for listener access
  const focusedUserRef = useRef(focusedUser)
  const filteredOptionsRef = useRef([])
  const noResultsRef = useRef(noResults)

  useEffect(() => {
    const debouncer = setTimeout(() => {
      setDebouncedInputText(inputText?.trim())
    }, 500)

    return () => {
      clearTimeout(debouncer)
    }
  }, [inputText])

  const {data} = useQuery(MENTIONABLE_USERS_QUERY, {
    variables: {
      discussionTopicId: ENV.discussion_topic_id,
      searchTerm: debouncedInputText,
    },
  })

  const mentionData = data?.legacyNode?.mentionableUsersConnection?.nodes || []

  const filteredOptions = useMemo(() => {
    return mentionData?.filter(o => {
      return o.name.toLowerCase().includes(inputText?.toLowerCase().trim())
    })
  }, [mentionData, inputText])

  useEffect(() => {
    filteredOptionsRef.current = filteredOptions
  }, [filteredOptions])

  const getXYPosition = useCallback(() => {
    const responseObj = getPosition(tinyMCE.activeEditor, `#${MARKER_ID}`)
    setMentionCoordinates(responseObj)
  }, [])

  // Navigates highlight of mention
  const navigateFocusedUser = dir => {
    setFocusType(KEYBOARD_FOCUS_TYPE)

    // Return if no options present
    if (filteredOptionsRef.current.length === 0) {
      return
    }

    // When no user is selected or filterSet doesn't contain focused user
    if (
      focusedUserRef.current === null ||
      !filteredOptionsRef.current.includes(focusedUserRef.current)
    ) {
      setFocusedUser(filteredOptionsRef.current[0])
      return
    }

    const selectedUser = focusedUserRef.current
    const selectedUserIndex = filteredOptionsRef.current.findIndex(m => m.id === selectedUser.id)

    switch (dir) {
      case 'down':
        setFocusedUser(
          filteredOptionsRef.current[
            selectedUserIndex + 1 >= filteredOptionsRef.current.length ? 0 : selectedUserIndex + 1
          ]
        )
        break
      case 'up':
        setFocusedUser(
          filteredOptionsRef.current[
            selectedUserIndex - 1 < 0
              ? filteredOptionsRef.current.length - 1
              : selectedUserIndex - 1
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
    // If no results then exit
    if (noResultsRef.current) {
      onExited(editor, false)
      return
    }

    getXYPosition()
    setInputText(value)
  }

  const messageCallback = e => {
    if (e.origin !== TRUSTED_MESSAGE_ORIGIN) {
      return
    }

    const subject = e.data.subject
    const value = e.data.value

    switch (subject) {
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

  // Prepare for exiting naturally
  useEffect(() => {
    // Check that last character isn't space and we have results
    if (mentionData.length === 0 && inputText.length > 0) {
      setNoResults(true)
      noResultsRef.current = true
    } else if (mentionData.length > 0) {
      setNoResults(false)
      noResultsRef.current = false
    }
  }, [inputText, mentionData])

  // When only spces exit without saving mention
  useEffect(() => {
    if (!inputText.replace(/\s/g, '').length && inputText.length > 0) {
      onExited(editor, false)
    }
  }, [editor, inputText, onExited])

  // Keep Focus User and active decendant always up to date
  useEffect(() => {
    if (focusedUser) {
      onFocusedUserChange({
        ...focusedUser,
        ariaActiveDescendantId: ARIA_ID_TEMPLATES.activeDescendant(editor.id, focusedUser.id),
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

  // Used to closing menu and selecting user after click
  useEffect(() => {
    if (shouldExit) {
      onExited(editor, true)
    }
  }, [editor, onExited, shouldExit])

  return (
    <>
      <MentionDropdownMenu
        instanceId={editor.id}
        mentionOptions={filteredOptions}
        coordiantes={mentionCoordinates}
        selectedUser={focusedUser?.id}
        onSelect={user => {
          setFocusedUser(user)
          setShouldExit(true)
        }}
        onMouseEnter={() => {
          setFocusType(MOUSE_FOCUS_TYPE)
        }}
        onOptionMouseEnter={user => {
          setFocusedUser(user)
        }}
        highlightMouse={focusType === MOUSE_FOCUS_TYPE}
      />
      <MentionDropdownPortal
        instanceId={editor.id}
        mentionOptions={filteredOptions}
        selectedUser={focusedUser?.id}
        rceBodyRef={rceRef}
      />
    </>
  )
}

export default MentionUIManager

MentionUIManager.propTypes = {
  rceRef: PropTypes.oneOfType([PropTypes.node, PropTypes.object]),
  onFocusedUserChange: PropTypes.func,
  onExited: PropTypes.func,
  editor: PropTypes.object,
}

MentionUIManager.defaultProps = {
  onFocusedUserChange: () => {},
  onExited: () => {},
}
