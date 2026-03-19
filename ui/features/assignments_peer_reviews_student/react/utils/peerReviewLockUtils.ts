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

import {Assignment} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

/**
 * Gets the unlock date for peer reviews.
 * If there's no unlockAt date set in peerReviewSubAssignment, we use the assignment due date.
 */
export function getPeerReviewUnlockDate(assignment: Assignment): string | null {
  const peerReviewSubAssignment = assignment.peerReviewSubAssignment
  if (!peerReviewSubAssignment) {
    return assignment.dueAt
  }

  return peerReviewSubAssignment.unlockAt || assignment.dueAt
}

/**
 * Gets the lock date for peer reviews.
 */
export function getPeerReviewLockDate(assignment: Assignment): string | null {
  const peerReviewSubAssignment = assignment.peerReviewSubAssignment
  if (!peerReviewSubAssignment) {
    return null
  }

  return peerReviewSubAssignment.lockAt
}

/**
 * Determines if the peer review is currently locked for the student (not yet unlocked).
 */
export function isPeerReviewLocked(assignment: Assignment): boolean {
  const unlockDate = getPeerReviewUnlockDate(assignment)

  if (!unlockDate) {
    return false
  }

  const now = new Date()
  const unlock = new Date(unlockDate)

  return now < unlock
}

/**
 * Determines if the peer review is past the lock date (i.e., closed for submissions).
 */
export function isPeerReviewPastLockDate(assignment: Assignment): boolean {
  const lockDate = getPeerReviewLockDate(assignment)

  if (!lockDate) {
    return false
  }

  const now = new Date()
  const lock = new Date(lockDate)

  return now > lock
}
