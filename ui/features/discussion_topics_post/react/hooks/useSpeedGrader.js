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

import {useEffect, useState} from 'react'

export default function useSpeedGrader() {
  const [isInSpeedGrader, setIsInSpeedGrader] = useState(false)
  const [currentStudentId, setCurrentStudentId] = useState(null)

  useEffect(() => {
    const checkSpeedGrader = () => {
      try {
        const currentUrl = new URL(window.location.href)
        const params = new URLSearchParams(currentUrl.search)

        setIsInSpeedGrader(params.get('speed_grader') === '1')
        setCurrentStudentId(params.get('student_id'))
      } catch (error) {
        setIsInSpeedGrader(false)
      }
    }
    checkSpeedGrader()
  }, [])

  const getStudentEntries = studentTopicQuery => {
    if (!currentStudentId) {
      return []
    }

    if (studentTopicQuery?.loading) {
      return []
    }

    const studentEntries =
      studentTopicQuery?.data?.legacyNode?.discussionEntriesConnection?.nodes || []

    return studentEntries
  }

  function getStudentPreviousEntry(currentEntryId, studentTopicQuery) {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const studentEntriesIds = studentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(currentEntryId)
    let prevEntryIndex = currentEntryIndex - 1
    if (currentEntryIndex === 0) {
      prevEntryIndex = studentEntriesIds.length - 1
    }
    const previousEntry = studentEntries[prevEntryIndex]
    return previousEntry || studentEntries[currentEntryId]
  }

  function getStudentNextEntry(currentEntryId, studentTopicQuery) {
    const studentEntries = getStudentEntries(studentTopicQuery)
    const studentEntriesIds = studentEntries.map(entry => entry._id)
    const currentEntryIndex = studentEntriesIds.indexOf(currentEntryId)
    let nextEntryIndex = currentEntryIndex + 1
    if (currentEntryIndex === studentEntriesIds.length - 1) {
      nextEntryIndex = 0
    }
    const nextEntry = studentEntries[nextEntryIndex]
    return nextEntry || studentEntries[currentEntryId]
  }

  const handleJumpFocusToSpeedGrader = () => {
    window.top.postMessage(
      {
        subject: 'SG.focusPreviousStudentButton',
      },
      '*'
    )
  }

  // These will be implemented later
  const handlePreviousStudentReply = null
  const handleNextStudentReply = null

  return {
    currentStudentId,
    getStudentPreviousEntry,
    getStudentNextEntry,
    isInSpeedGrader,
    handlePreviousStudentReply,
    handleNextStudentReply,
    handleJumpFocusToSpeedGrader,
  }
}
