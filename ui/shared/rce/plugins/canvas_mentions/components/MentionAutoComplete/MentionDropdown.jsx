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
import {useQuery} from '@apollo/client'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('mentions')

const MOUSE_FOCUS_TYPE = 'mouse'
const KEYBOARD_FOCUS_TYPE = 'keyboard'
const LOAD_MORE_MARKER = {id: '__LOAD_MORE__', name: I18n.t('Load More Users'), isLoadMore: true}

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
  const hasNextPageRef = useRef(false)

  useEffect(() => {
    const debouncer = setTimeout(() => {
      setDebouncedInputText(inputText?.trim())
    }, 500)

    return () => {
      clearTimeout(debouncer)
    }
  }, [inputText])

  const {data, loading, fetchMore} = useQuery(MENTIONABLE_USERS_QUERY, {
    variables: {
      discussionTopicId: ENV.discussion_topic_id,
      searchTerm: debouncedInputText,
      after: null,
    },
  })

  const mentionData = data?.legacyNode?.mentionableUsersConnection?.nodes || []
  const pageInfo = data?.legacyNode?.mentionableUsersConnection?.pageInfo

  const filteredOptions = useMemo(() => {
    return mentionData?.filter(o => {
      return (
        o.name.toLowerCase().includes(inputText?.toLowerCase().trim()) ||
        o.shortName.toLowerCase().includes(inputText?.toLowerCase().trim())
      )
    })
  }, [mentionData, inputText])

  // Create navigable options including "Load More" if needed
  const navigableOptions = useMemo(() => {
    const options = [...filteredOptions]
    if (pageInfo?.hasNextPage && !loading) {
      options.push(LOAD_MORE_MARKER)
    }
    return options
  }, [filteredOptions, pageInfo?.hasNextPage, loading])

  useEffect(() => {
    filteredOptionsRef.current = navigableOptions
    hasNextPageRef.current = pageInfo?.hasNextPage
  }, [navigableOptions, pageInfo?.hasNextPage])

  // Store pageInfo in ref for stable access
  const pageInfoRef = useRef(pageInfo)
  useEffect(() => {
    if (pageInfo) {
      pageInfoRef.current = pageInfo
    }
  }, [pageInfo])

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
          ],
        )
        break
      case 'up':
        setFocusedUser(
          filteredOptionsRef.current[
            selectedUserIndex - 1 < 0
              ? filteredOptionsRef.current.length - 1
              : selectedUserIndex - 1
          ],
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
      case KEY_NAMES[KEY_CODES.enter]:
      case KEY_NAMES[KEY_CODES.tab]:
        // Enter or Tab - check if Load More is focused
        if (focusedUserRef.current?.isLoadMore) {
          handleLoadMore()
          // Prevent the default mention insertion
          return
        }
        break
      default:
        break
    }
  }

  const handleInputChange = value => {
    // Don't exit just because there are no results - let users keep typing
    // Only exit if the input becomes empty or only spaces
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
    // Only mark as no results if we're not loading and have no data
    if (mentionData.length === 0 && inputText.length > 0 && !loading) {
      setNoResults(true)
      noResultsRef.current = true
    } else if (mentionData.length > 0 || loading) {
      setNoResults(false)
      noResultsRef.current = false
    }
  }, [inputText, mentionData, loading])

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
        isLoadMore: focusedUser.isLoadMore, // Pass through the isLoadMore flag
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

  const handleLoadMore = useCallback(() => {
    const currentPageInfo = pageInfoRef.current
    // Count only real users, not the Load More marker
    const currentUserCount = filteredOptionsRef.current.filter(u => !u.isLoadMore).length
    if (currentPageInfo?.hasNextPage) {
      fetchMore({
        variables: {
          after: currentPageInfo.endCursor,
        },
      })
        .then(() => {
          // Wait a bit for the filteredOptionsRef to update, then focus the first newly loaded user
          setTimeout(() => {
            const newUserCount = filteredOptionsRef.current.filter(u => !u.isLoadMore).length
            if (newUserCount > currentUserCount && filteredOptionsRef.current[currentUserCount]) {
              setFocusedUser(filteredOptionsRef.current[currentUserCount])
              setFocusType(KEYBOARD_FOCUS_TYPE)
            }
          }, 100)
        })
        .catch(err => {
          console.error('Error loading more users:', err)
        })
    }
  }, [fetchMore, loading])

  const handleSelect = useCallback(
    user => {
      // If "Load More" is selected, load more users instead of exiting
      if (user?.isLoadMore) {
        handleLoadMore()
        // Don't set focusedUser or shouldExit for Load More
        return
      }

      // Only set user and exit for actual user selections
      setFocusedUser(user)
      setShouldExit(true)
    },
    [handleLoadMore],
  )

  return (
    <>
      <MentionDropdownMenu
        instanceId={editor.id}
        mentionOptions={filteredOptions}
        coordiantes={mentionCoordinates}
        selectedUser={focusedUser?.id}
        onSelect={handleSelect}
        onMouseEnter={() => {
          setFocusType(MOUSE_FOCUS_TYPE)
        }}
        onOptionMouseEnter={user => {
          setFocusedUser(user)
        }}
        highlightMouse={focusType === MOUSE_FOCUS_TYPE}
        isLoading={loading}
        hasNextPage={pageInfo?.hasNextPage}
        onLoadMore={handleLoadMore}
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
