/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useEffect, useState, useCallback} from 'react'
import {STUDENT_DISCUSSION_QUERY} from '../../graphql/Queries'
import {useQuery} from 'react-apollo'
import {isSpeedGraderInTopUrl} from '../utils/constants'

export default function useSpeedGrader({
  highlightEntryId = '',
  setHighlightEntryId = () => {},
  setPageNumber = () => {},
  expandedThreads,
  setExpandedThreads = () => {},
  setFocusSelector = () => {},
  sort = 'desc',
  discussionID = '',
  perPage = 20,
} = {}) {
  const [isInSpeedGrader, setIsInSpeedGrader] = useState(false)
  const [currentStudentId, setCurrentStudentId] = useState(null)

  useEffect(() => {
    const checkSpeedGrader = () => {
      try {
        const currentUrl = new URL(window.location.href)
        const params = new URLSearchParams(currentUrl.search)

        setIsInSpeedGrader(isSpeedGraderInTopUrl)
        setCurrentStudentId(params.get('student_id'))
      } catch (error) {
        setIsInSpeedGrader(false)
      }
    }
    checkSpeedGrader()
  }, [])

  // perPage and sort should match discussionTopicQuery
  const studentTopicVariables = {
    discussionID,
    userSearchId: currentStudentId,
    perPage,
    sort,
  }

  const studentTopicQuery = useQuery(STUDENT_DISCUSSION_QUERY, {
    variables: studentTopicVariables,
    fetchPolicy: 'cache-and-network',
    skip: !(isInSpeedGrader && currentStudentId && studentTopicVariables.discussionID),
  })

  const getStudentEntries = useCallback(() => {
    if (!currentStudentId) {
      return []
    }

    if (studentTopicQuery?.loading) {
      return []
    }

    const studentEntries =
      studentTopicQuery?.data?.legacyNode?.discussionEntriesConnection?.nodes || []

    return studentEntries
  }, [studentTopicQuery, currentStudentId])

  const navigateToEntry = useCallback(
    newEntry => {
      setHighlightEntryId(newEntry?._id || highlightEntryId)
      setPageNumber(newEntry?.rootEntryPageNumber)
      if (newEntry?.rootEntryId) {
        setExpandedThreads([...expandedThreads, newEntry.rootEntryId])
      }
    },
    [expandedThreads, highlightEntryId, setExpandedThreads, setHighlightEntryId, setPageNumber]
  )

  const getStudentPreviousEntry = useCallback(() => {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const studentEntriesIds = studentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(highlightEntryId)
    let prevEntryIndex = currentEntryIndex - 1
    if (currentEntryIndex === 0) {
      prevEntryIndex = studentEntriesIds.length - 1
    }
    const previousEntry = studentEntries[prevEntryIndex]
    navigateToEntry(previousEntry)
  }, [getStudentEntries, studentTopicQuery, highlightEntryId, navigateToEntry])

  const getStudentNextEntry = useCallback(() => {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const studentEntriesIds = studentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(highlightEntryId)
    let nextEntryIndex = currentEntryIndex + 1
    if (currentEntryIndex === studentEntriesIds.length - 1) {
      nextEntryIndex = 0
    }
    const nextEntry = studentEntries[nextEntryIndex]
    navigateToEntry(nextEntry)
  }, [getStudentEntries, studentTopicQuery, highlightEntryId, navigateToEntry])

  const onMessage = useCallback(
    e => {
      const message = e.data
      if (highlightEntryId) {
        switch (message.subject) {
          case 'DT.previousStudentReply': {
            getStudentPreviousEntry()
            break
          }
          case 'DT.nextStudentReply': {
            getStudentNextEntry()
            break
          }
        }
      }
    },
    [highlightEntryId, getStudentPreviousEntry, getStudentNextEntry]
  )

  useEffect(() => {
    window.addEventListener('message', onMessage)
    return () => {
      window.removeEventListener('message', onMessage)
    }
  }, [highlightEntryId, onMessage])

  const handleJumpFocusToSpeedGrader = () => {
    window.top.postMessage(
      {
        subject: 'SG.focusPreviousStudentButton',
      },
      '*'
    )
  }

  function sendPostMessage(message) {
    window.postMessage(message, '*')
  }

  function handlePreviousStudentReply() {
    const message = {subject: 'DT.previousStudentReply'}
    sendPostMessage(message)
    setFocusSelector('#previous-in-speedgrader')
  }

  const handleNextStudentReply = () => {
    const message = {subject: 'DT.nextStudentReply'}
    sendPostMessage(message)
    setFocusSelector('#next-in-speedgrader')
  }

  return {
    isInSpeedGrader,
    handlePreviousStudentReply,
    handleNextStudentReply,
    handleJumpFocusToSpeedGrader,
  }
}
