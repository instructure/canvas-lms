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
import {useQuery} from '@apollo/client'
import useSpeedGrader from './useSpeedGrader'

export default function useNavigateEntries({
  highlightEntryId = '',
  setHighlightEntryId = () => {},
  setPageNumber = () => {},
  expandedThreads,
  setExpandedThreads = () => {},
  setFocusSelector = () => {},
  discussionID = '',
  perPage = 20,
  sort = '',
} = {}) {
  const {isInSpeedGrader} = useSpeedGrader()
  const [currentStudentId, setCurrentStudentId] = useState(null)

  useEffect(() => {
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)
    if (params.get('student_id') !== currentStudentId) {
      setCurrentStudentId(params.get('student_id'))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // perPage should match discussionTopicQuery
  const studentTopicVariables = {
    discussionID,
    userSearchId: currentStudentId,
    perPage,
  }

  const studentTopicQuery = useQuery(STUDENT_DISCUSSION_QUERY, {
    variables: studentTopicVariables,
    fetchPolicy: 'cache-and-network',
    skip: !(isInSpeedGrader && currentStudentId && studentTopicVariables.discussionID)
  })

  const getStudentEntries = useCallback(() => {
    if (!currentStudentId) {
      return []
    }

    if (studentTopicQuery?.loading) {
      return []
    }

    let studentEntries = studentTopicQuery?.data?.legacyNode?.discussionEntriesConnection?.nodes
    if (studentEntries) {
      studentEntries = [...studentEntries]
       // sortOrder should always be asc, that way first entry is always oldest.
      // Due to VICE-4808 sortOrder param is disabled.
      studentEntries.sort((a, b) => {
        return parseInt(a._id, 10) - parseInt(b._id, 10);
      })
    }

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
    [expandedThreads, highlightEntryId, setExpandedThreads, setHighlightEntryId, setPageNumber],
  )

  const getStudentFirstEntry = useCallback(() => {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const firstEntry = studentEntries[0]
    navigateToEntry(firstEntry)
  }, [getStudentEntries, studentTopicQuery, highlightEntryId, navigateToEntry])

  const getStudentLastEntry = useCallback(() => {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const studentEntriesIds = studentEntries.map(entry => entry._id)
    const lastEntry = studentEntries[studentEntriesIds.length - 1]
    navigateToEntry(lastEntry)
  }, [getStudentEntries, studentTopicQuery, highlightEntryId, navigateToEntry])

  const getStudentPreviousEntry = useCallback(() => {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const studentEntriesIds = studentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(highlightEntryId)

    if(ENV?.FEATURES?.discussions_speedgrader_revisit) {
      if (currentEntryIndex > 0) {
        const prevEntryIndex = currentEntryIndex - 1
        const previousEntry = studentEntries[prevEntryIndex]
        navigateToEntry(previousEntry)
      }
    } else {
      let prevEntryIndex = currentEntryIndex - 1
      if (currentEntryIndex === 0) {
        prevEntryIndex = studentEntriesIds.length - 1
      }
      const previousEntry = studentEntries[prevEntryIndex]
      navigateToEntry(previousEntry)
    }
  }, [getStudentEntries, studentTopicQuery, highlightEntryId, navigateToEntry])

  const getStudentNextEntry = useCallback(() => {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const studentEntriesIds = studentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(highlightEntryId)

    if(ENV?.FEATURES?.discussions_speedgrader_revisit) {
      if (currentEntryIndex < studentEntriesIds.length - 1) {
        const nextEntryIndex = currentEntryIndex + 1
        const nextEntry = studentEntries[nextEntryIndex]
        navigateToEntry(nextEntry)
      }
    } else {
      let nextEntryIndex = currentEntryIndex + 1
      if (currentEntryIndex === studentEntriesIds.length - 1) {
        nextEntryIndex = 0
      }
      const nextEntry = studentEntries[nextEntryIndex]
      navigateToEntry(nextEntry)
    }
  }, [getStudentEntries, studentTopicQuery, highlightEntryId, navigateToEntry])

  const onMessage = useCallback(
    e => {
      const message = e.data
      if (highlightEntryId) {
        switch (message.subject) {
          case 'DT.firstStudentReply': {
            getStudentFirstEntry()
            break
          }
          case 'DT.lastStudentReply': {
            getStudentLastEntry()
            break
          }
          case 'DT.previousStudentReply': {
            getStudentPreviousEntry()
            break
          }
          case 'DT.nextStudentReply': {
            getStudentNextEntry()
            break
          }
          case 'DT.previousStudentReplyTab': {
            setFocusSelector('#previous-in-speedgrader')
            getStudentPreviousEntry()
            break
          }
          case 'DT.nextStudentReplyTab': {
            setFocusSelector('#next-in-speedgrader')
            getStudentNextEntry()
            break
          }
        }
      }
    },
    [highlightEntryId, getStudentPreviousEntry, getStudentNextEntry, setFocusSelector],
  )

  useEffect(() => {
    window.addEventListener('message', onMessage)
    return () => {
      window.removeEventListener('message', onMessage)
    }
  }, [highlightEntryId, onMessage])

  // Set highlight default entry; we already set this in iframe for new student. only trigger on new student.
  useEffect(() => {
    if (!isInSpeedGrader) {
      return
    }

    if (studentTopicQuery?.loading) {
      return
    }
    const studentEntries = getStudentEntries()
    if(studentEntries) {
      const studentEntriesIds = studentEntries.map(entry => entry._id)
      let currentEntryIndex = studentEntriesIds.indexOf(highlightEntryId)
      currentEntryIndex = currentEntryIndex >= 0 ? currentEntryIndex : studentEntriesIds.indexOf(`${Math.min(...studentEntriesIds)}`)
      if(studentEntries[currentEntryIndex]){
        navigateToEntry(studentEntries[currentEntryIndex])
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [getStudentEntries, sort])
}
