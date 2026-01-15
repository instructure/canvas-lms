/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useEffect, useState, useRef} from 'react'
import PeerReviewDueDateTimeInput from './PeerReviewDueDateTimeInput'
import PeerReviewAvailableFromDateTimeInput from './PeerReviewAvailableFromDateTimeInput'
import PeerReviewAvailableToDateTimeInput from './PeerReviewAvailableToDateTimeInput'
import type {DateLockTypes, CustomDateTimeInputProps} from '../types'

type PeerReviewSelectorProps = CustomDateTimeInputProps & {
  assignmentDueDate: string | null
  peerReviewAvailableToDate: string | null
  setPeerReviewAvailableToDate: (date: string | null) => void
  handlePeerReviewAvailableToDateChange: (
    _event: React.SyntheticEvent,
    value: string | undefined,
  ) => void
  peerReviewAvailableFromDate: string | null
  setPeerReviewAvailableFromDate: (date: string | null) => void
  handlePeerReviewAvailableFromDateChange: (
    _event: React.SyntheticEvent,
    value: string | undefined,
  ) => void
  peerReviewDueDate: string | null
  setPeerReviewDueDate: (date: string | null) => void
  handlePeerReviewDueDateChange: (_event: React.SyntheticEvent, value: string | undefined) => void
  validationErrors?: Record<string, string>
  unparsedFieldKeys?: Set<string>
  blueprintDateLocks?: DateLockTypes[] | undefined
  dateInputRefs?: Record<string, HTMLInputElement | null>
  timeInputRefs?: Record<string, HTMLInputElement | null>
  handleBlur: (key: string) => (event: React.FocusEvent<HTMLInputElement>) => void
  clearButtonAltLabels: Record<'dueDateLabel' | 'availableFromLabel' | 'availableToLabel', string>
}

const PeerReviewSelector = ({
  assignmentDueDate,
  peerReviewAvailableToDate,
  setPeerReviewAvailableToDate,
  handlePeerReviewAvailableToDateChange,
  peerReviewAvailableFromDate,
  setPeerReviewAvailableFromDate,
  handlePeerReviewAvailableFromDateChange,
  peerReviewDueDate,
  setPeerReviewDueDate,
  handlePeerReviewDueDateChange,
  clearButtonAltLabels,
  ...rest
}: PeerReviewSelectorProps) => {
  const [peerReviewEnabled, setPeerReviewEnabled] = useState(false)

  const checkPeerReviewState = () => {
    // Check if the "Require Peer Reviews" checkbox is actually checked
    const checkbox = document.getElementById(
      'assignment_peer_reviews_checkbox',
    ) as HTMLInputElement | null
    const isChecked = checkbox?.checked ?? false
    setPeerReviewEnabled(isChecked)
  }

  useEffect(() => {
    // Check initial state
    checkPeerReviewState()

    const handlePeerReviewToggle = (event: MessageEvent) => {
      if (event.data?.subject === 'ASGMT.togglePeerReviews') {
        // When we receive the toggle event, check the actual checkbox state
        // This handles cases where moderated grading enables/disables the checkbox
        setTimeout(checkPeerReviewState, 0)
      }
    }

    const handleCheckboxChange = () => {
      checkPeerReviewState()
    }

    // Listen for peer review toggle messages from EditView
    window.addEventListener('message', handlePeerReviewToggle as EventListener)

    // Listen for changes to the checkbox itself
    const checkbox = document.getElementById('assignment_peer_reviews_checkbox')
    checkbox?.addEventListener('change', handleCheckboxChange)

    return () => {
      window.removeEventListener('message', handlePeerReviewToggle as EventListener)
      checkbox?.removeEventListener('change', handleCheckboxChange)
    }
  }, [])

  // Clear peer review dates when assignment due date is cleared
  const prevAssignmentDueDateRef = useRef(assignmentDueDate)
  useEffect(() => {
    // Only clear if peer review is actually enabled and visible
    if (!ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED || !peerReviewEnabled) {
      return
    }

    // Only clear if assignment due date changed from something to null
    const dueDateWasCleared =
      prevAssignmentDueDateRef.current !== null && assignmentDueDate === null
    prevAssignmentDueDateRef.current = assignmentDueDate

    if (dueDateWasCleared) {
      setPeerReviewDueDate(null)
      setPeerReviewAvailableFromDate(null)
      setPeerReviewAvailableToDate(null)
    }
  }, [
    assignmentDueDate,
    peerReviewEnabled,
    setPeerReviewDueDate,
    setPeerReviewAvailableFromDate,
    setPeerReviewAvailableToDate,
  ])

  // Clear peer review dates when peer review is disabled
  const prevPeerReviewEnabledRef = useRef(peerReviewEnabled)
  useEffect(() => {
    // Only clear if peer review feature is enabled globally
    if (!ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED) {
      return
    }

    // Only clear if peer review was disabled (changed from true to false)
    const peerReviewWasDisabled =
      prevPeerReviewEnabledRef.current === true && peerReviewEnabled === false
    prevPeerReviewEnabledRef.current = peerReviewEnabled

    if (peerReviewWasDisabled) {
      setPeerReviewDueDate(null)
      setPeerReviewAvailableFromDate(null)
      setPeerReviewAvailableToDate(null)
    }
  }, [
    peerReviewEnabled,
    setPeerReviewDueDate,
    setPeerReviewAvailableFromDate,
    setPeerReviewAvailableToDate,
  ])

  if (!ENV?.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED || !peerReviewEnabled) {
    return null
  }

  const {dueDateLabel, availableFromLabel, availableToLabel} = clearButtonAltLabels
  const isPeerReviewDisabled = assignmentDueDate === null

  return (
    <>
      <PeerReviewDueDateTimeInput
        peerReviewDueDate={peerReviewDueDate}
        setPeerReviewDueDate={setPeerReviewDueDate}
        handlePeerReviewDueDateChange={handlePeerReviewDueDateChange}
        clearButtonAltLabel={dueDateLabel}
        disabled={isPeerReviewDisabled}
        {...rest}
      />
      <PeerReviewAvailableFromDateTimeInput
        peerReviewAvailableFromDate={peerReviewAvailableFromDate}
        setPeerReviewAvailableFromDate={setPeerReviewAvailableFromDate}
        handlePeerReviewAvailableFromDateChange={handlePeerReviewAvailableFromDateChange}
        clearButtonAltLabel={availableFromLabel}
        disabled={isPeerReviewDisabled}
        {...rest}
      />
      <PeerReviewAvailableToDateTimeInput
        peerReviewAvailableToDate={peerReviewAvailableToDate}
        setPeerReviewAvailableToDate={setPeerReviewAvailableToDate}
        handlePeerReviewAvailableToDateChange={handlePeerReviewAvailableToDateChange}
        clearButtonAltLabel={availableToLabel}
        disabled={isPeerReviewDisabled}
        {...rest}
      />
    </>
  )
}

export default PeerReviewSelector
