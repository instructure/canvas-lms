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

import {useEffect, useState, useCallback, useMemo} from 'react'
import {useStudentEntries} from './useStudentEntries'
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
  const STUDENT_ENTRIES_PER_PAGE = 100

  useEffect(() => {
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)
    const studentIdParam = params.get('student_id')
    if (studentIdParam !== currentStudentId) {
      setCurrentStudentId(studentIdParam)
    }
  }, [currentStudentId])

  const studentEntriesQuery = useStudentEntries(
    discussionID,
    STUDENT_ENTRIES_PER_PAGE,
    perPage,
    currentStudentId,
  )

  useEffect(() => {
    if (!studentEntriesQuery.isLoading && sort) {
      studentEntriesQuery.refetch();
    }
  }, [sort, studentEntriesQuery]);

  // Combine pages from your query and sort them based on `sort` ("asc"/"desc").
  const sortedStudentEntries = useMemo(() => {
    if (!currentStudentId || studentEntriesQuery.isLoading) return []

    const pages = studentEntriesQuery.data?.pages || []
    const combined = pages.flatMap(page => page.entries) || []

    // Sort by numeric value of _id, ascending or descending
    return combined.sort((a, b) => {
      const aNum = Number(a._id)
      const bNum = Number(b._id)
      return sort === 'desc' ? bNum - aNum : aNum - bNum
    })
  }, [currentStudentId, studentEntriesQuery.data, studentEntriesQuery.isLoading, sort])

  const navigateToEntry = useCallback(
    newEntry => {
      if (!newEntry) return
      setHighlightEntryId(newEntry._id)
      setPageNumber(newEntry.rootEntryPageNumber)
      if (newEntry.rootEntryId) {
        setExpandedThreads([...expandedThreads, newEntry.rootEntryId])
      }
    },
    [expandedThreads, setExpandedThreads, setHighlightEntryId, setPageNumber],
  )

  const getStudentFirstEntry = useCallback(() => {
    const firstEntry = sortedStudentEntries[0]
    navigateToEntry(firstEntry)
  }, [sortedStudentEntries, navigateToEntry])

  const getStudentLastEntry = useCallback(() => {
    const lastEntry = sortedStudentEntries[sortedStudentEntries.length - 1]
    navigateToEntry(lastEntry)
  }, [sortedStudentEntries, navigateToEntry])

  const getStudentPreviousEntry = useCallback(() => {
    if (!highlightEntryId) return
    const studentEntriesIds = sortedStudentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(highlightEntryId)
    if (currentEntryIndex <= 0) {
      const wrapIndex = sortedStudentEntries.length - 1
      navigateToEntry(sortedStudentEntries[wrapIndex])
    } else {
      navigateToEntry(sortedStudentEntries[currentEntryIndex - 1])
    }
  }, [sortedStudentEntries, highlightEntryId, navigateToEntry])

  const getStudentNextEntry = useCallback(() => {
    if (!highlightEntryId) return
    const studentEntriesIds = sortedStudentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(highlightEntryId)
    if (currentEntryIndex < 0 || currentEntryIndex === studentEntriesIds.length - 1) {
      navigateToEntry(sortedStudentEntries[0])
    } else {
      navigateToEntry(sortedStudentEntries[currentEntryIndex + 1])
    }
  }, [sortedStudentEntries, highlightEntryId, navigateToEntry])

  const onMessage = useCallback(
    e => {
      const message = e.data
      if (highlightEntryId) {
        switch (message.subject) {
          case 'DT.firstStudentReply':
            getStudentFirstEntry()
            break
          case 'DT.lastStudentReply':
            getStudentLastEntry()
            break
          case 'DT.previousStudentReply':
            getStudentPreviousEntry()
            break
          case 'DT.nextStudentReply':
            getStudentNextEntry()
            break
          case 'DT.previousStudentReplyTab':
            setFocusSelector('#previous-in-speedgrader')
            getStudentPreviousEntry()
            break
          case 'DT.nextStudentReplyTab':
            setFocusSelector('#next-in-speedgrader')
            getStudentNextEntry()
            break
        }
      }
    },
    [
      highlightEntryId,
      getStudentFirstEntry,
      getStudentLastEntry,
      getStudentPreviousEntry,
      getStudentNextEntry,
      setFocusSelector,
    ],
  )

  useEffect(() => {
    window.addEventListener('message', onMessage)
    return () => {
      window.removeEventListener('message', onMessage)
    }
  }, [highlightEntryId, onMessage])

  // When the student changes, or sort changes, or entries finish loading,
  // if highlightEntryId isn't in the list, pick the "first" item (per sorted order).
  useEffect(() => {
    if (!isInSpeedGrader || studentEntriesQuery.isLoading) return

    const currentEntryIndex = sortedStudentEntries.findIndex(e => e._id === highlightEntryId)
    if (currentEntryIndex < 0 && sortedStudentEntries.length > 0) {
      // highlightEntryId not found -> go to the "first" entry in sorted order
      navigateToEntry(sortedStudentEntries[0])
    }
  }, [
    isInSpeedGrader,
    studentEntriesQuery.isLoading,
    highlightEntryId,
    sortedStudentEntries,
    navigateToEntry,
  ])
}
