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

import {useCallback, useEffect, useMemo, useState} from 'react'
import {ScheduledRelease} from '../ScheduledReleasePolicy'
import {useGetAssignmentScheduledPost} from '../../queries/useGetAssignmentScheduledPost'
import {validateRelease, hasScheduledReleaseChanged, type ErrorMessages} from '../utils/utils'

type UseScheduledReleaseOptions = {
  assignmentId: string
  onScheduledReleaseChange: (changes: Partial<ScheduledRelease>) => void
}

type ScheduledReleaseState = {
  scheduledPost: ScheduledRelease | null
  errorMessages: ErrorMessages
}

export const useScheduledRelease = ({
  assignmentId,
  onScheduledReleaseChange,
}: UseScheduledReleaseOptions) => {
  const {data: fetchedScheduledPost} = useGetAssignmentScheduledPost(assignmentId)
  const [scheduledReleaseState, setScheduledReleaseState] = useState<ScheduledReleaseState>({
    scheduledPost: null,
    errorMessages: {grades: [], comments: []},
  })

  useEffect(() => {
    const scheduledPostMode = !fetchedScheduledPost
      ? undefined
      : fetchedScheduledPost.postCommentsAt === fetchedScheduledPost.postGradesAt
        ? 'shared'
        : 'separate'

    const initialRelease: ScheduledRelease = {
      postCommentsAt: fetchedScheduledPost?.postCommentsAt || null,
      postGradesAt: fetchedScheduledPost?.postGradesAt || null,
      scheduledPostMode,
    }

    setScheduledReleaseState({
      scheduledPost: initialRelease,
      errorMessages: {grades: [], comments: []},
    })
  }, [fetchedScheduledPost])

  const handleScheduledReleaseChange = useCallback(
    (changes: Partial<ScheduledRelease>) => {
      const newScheduledRelease = {...scheduledReleaseState.scheduledPost, ...changes}
      const newErrors = validateRelease(newScheduledRelease, fetchedScheduledPost)

      setScheduledReleaseState({
        scheduledPost: newScheduledRelease,
        errorMessages: newErrors,
      })

      onScheduledReleaseChange(newScheduledRelease)
    },
    [onScheduledReleaseChange, fetchedScheduledPost, scheduledReleaseState.scheduledPost],
  )

  const validateScheduledRelease = useCallback((): boolean => {
    const errors = validateRelease(scheduledReleaseState.scheduledPost, fetchedScheduledPost, true)
    setScheduledReleaseState(prev => ({...prev, errorMessages: errors}))
    return errors.grades.length === 0 && errors.comments.length === 0
  }, [scheduledReleaseState.scheduledPost, fetchedScheduledPost])

  const hasChanged = useMemo(
    () => hasScheduledReleaseChanged(scheduledReleaseState.scheduledPost, fetchedScheduledPost),
    [scheduledReleaseState.scheduledPost, fetchedScheduledPost],
  )

  return {
    scheduledPost: scheduledReleaseState.scheduledPost,
    scheduledReleaseErrorMessages: scheduledReleaseState.errorMessages,
    hasScheduledReleaseChanged: hasChanged,
    handleScheduledReleaseChange,
    validateScheduledRelease,
  }
}
