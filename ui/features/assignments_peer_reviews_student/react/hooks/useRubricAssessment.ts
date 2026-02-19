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

import {useState, useEffect} from 'react'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'
import type {ViewMode} from '@canvas/rubrics/react/RubricAssessment/ViewModeSelect'
import useLocalStorage from '@canvas/local-storage'
import * as RUBRIC_CONSTANTS from '@canvas/rubrics/react/RubricAssessment/constants'
import {useSavePeerReviewRubricAssessment} from './useSavePeerReviewRubricAssessment'
import type {
  Assignment,
  RubricAssessmentRating,
} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

const I18n = createI18nScope('peer_reviews_student')

interface UseRubricAssessmentProps {
  assignment: Assignment
  submissionId: string
  submissionUserId?: string
  submissionAnonymousId?: string | null
  rubricAssessment?: {
    _id: string
    assessmentRatings: RubricAssessmentRating[]
  } | null
  isPeerReviewCompleted: boolean
  onRubricSubmitted?: () => void
}

export const useRubricAssessment = ({
  assignment,
  submissionId,
  submissionUserId,
  submissionAnonymousId,
  rubricAssessment,
  isPeerReviewCompleted,
  onRubricSubmitted,
}: UseRubricAssessmentProps) => {
  const [rubricAssessmentData, setRubricAssessmentData] = useState<RubricAssessmentData[]>([])
  const [rubricAssessmentCompleted, setRubricAssessmentCompleted] = useState(isPeerReviewCompleted)
  const [rubricViewMode, setRubricViewMode] = useLocalStorage<ViewMode>(
    RUBRIC_CONSTANTS.RUBRIC_VIEW_MODE_LOCALSTORAGE_KEY(ENV.current_user_id ?? ''),
    'vertical',
  )

  const {mutate: saveRubricAssessment} = useSavePeerReviewRubricAssessment()

  useEffect(() => {
    if (rubricAssessment && assignment.rubric) {
      const transformedData: RubricAssessmentData[] = rubricAssessment.assessmentRatings.map(
        assessmentRating => ({
          id: assessmentRating._id,
          points: assessmentRating.points,
          criterionId: assessmentRating.criterion._id,
          comments: assessmentRating.comments ?? '',
          commentsEnabled: true,
          description: assessmentRating.description ?? '',
        }),
      )
      setRubricAssessmentData(transformedData)
      setRubricAssessmentCompleted(true)
    } else {
      setRubricAssessmentData([])
      setRubricAssessmentCompleted(false)
    }
  }, [submissionId, isPeerReviewCompleted, rubricAssessment, assignment.rubric])

  const handleRubricSubmit = (assessment: RubricAssessmentData[]) => {
    if (!assignment.rubric || !assignment.rubricAssociation) {
      showFlashAlert({
        message: I18n.t('Unable to submit rubric assessment. Missing rubric information.'),
        type: 'error',
      })
      return
    }

    saveRubricAssessment(
      {
        assessments: assessment,
        courseId: assignment.courseId,
        rubricAssociationId: assignment.rubricAssociation._id,
        revieweeUserId: submissionUserId,
        anonymousId: submissionAnonymousId ?? undefined,
      },
      {
        onSuccess: () => {
          setRubricAssessmentData(assessment)
          setRubricAssessmentCompleted(true)
          onRubricSubmitted?.()
        },
        onError: () => {
          showFlashAlert({
            message: I18n.t('Failed to save rubric assessment.'),
            type: 'error',
          })
        },
      },
    )
  }

  const resetRubricAssessment = () => {
    setRubricAssessmentCompleted(false)
  }

  return {
    rubricAssessmentData,
    rubricAssessmentCompleted,
    rubricViewMode,
    setRubricViewMode,
    handleRubricSubmit,
    resetRubricAssessment,
  }
}
