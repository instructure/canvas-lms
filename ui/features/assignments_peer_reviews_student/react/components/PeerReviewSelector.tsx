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

import React from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconCompleteLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AssessmentRequest} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

const I18n = createI18nScope('peer_reviews_student')

interface PeerReviewSelectorProps {
  assessmentRequests: AssessmentRequest[]
  selectedIndex: number
  onSelectionChange: (index: number) => void
  requiredPeerReviewCount: number
}

export const PeerReviewSelector = ({
  assessmentRequests,
  selectedIndex,
  onSelectionChange,
  requiredPeerReviewCount,
}: PeerReviewSelectorProps) => {
  // Include all assessment requests (both available and unavailable due to missing submissions)
  const availableAssessments = assessmentRequests ?? []
  const hasAssessments = availableAssessments.length > 0
  const unavailableCount = Math.max(0, requiredPeerReviewCount - availableAssessments.length)

  const handleChange = (_event: React.SyntheticEvent, data: {value?: string | number}) => {
    const index = Number(data.value)
    onSelectionChange(index)
  }

  const readyToReview = availableAssessments.filter(
    assessment =>
      assessment.workflowState === 'assigned' &&
      assessment.submission?.submittedAt !== null &&
      assessment.submission?.submittedAt !== undefined,
  )

  const completedReviews = availableAssessments.filter(
    assessment =>
      assessment.workflowState === 'completed' &&
      assessment.submission?.submittedAt !== null &&
      assessment.submission?.submittedAt !== undefined,
  )

  const submissionNotAvailable = availableAssessments.filter(
    assessment => !assessment.submission?.submittedAt,
  )

  const renderChildren = () => {
    if (!hasAssessments && unavailableCount === 0) {
      return (
        <SimpleSelect.Option id="no-peer-reviews" value="no-peer-reviews">
          {I18n.t('No peer reviews available')}
        </SimpleSelect.Option>
      )
    }

    const children: React.ReactNode[] = []

    if (readyToReview.length > 0) {
      children.push(
        <SimpleSelect.Group key="ready-group" renderLabel={I18n.t('Ready to Review')}>
          {readyToReview.map(assessment => {
            const index = availableAssessments.indexOf(assessment)
            return (
              <SimpleSelect.Option
                key={assessment._id}
                id={`peer-review-option-${index}`}
                value={String(index)}
              >
                {I18n.t('Peer Review (%{number} of %{total})', {
                  number: index + 1,
                  total: requiredPeerReviewCount,
                })}
              </SimpleSelect.Option>
            )
          })}
        </SimpleSelect.Group>,
      )
    }

    if (completedReviews.length > 0) {
      children.push(
        <SimpleSelect.Group key="completed-group" renderLabel={I18n.t('Completed Peer Reviews')}>
          {completedReviews.map(assessment => {
            const index = availableAssessments.indexOf(assessment)
            return (
              <SimpleSelect.Option
                key={assessment._id}
                id={`peer-review-option-${index}`}
                value={String(index)}
                renderBeforeLabel={<IconCompleteLine />}
              >
                {I18n.t('Peer Review (%{number} of %{total})', {
                  number: index + 1,
                  total: requiredPeerReviewCount,
                })}
              </SimpleSelect.Option>
            )
          })}
        </SimpleSelect.Group>,
      )
    }

    if (submissionNotAvailable.length > 0 || unavailableCount > 0) {
      children.push(
        <SimpleSelect.Group key="unavailable-group" renderLabel={I18n.t('Not Yet Available')}>
          {submissionNotAvailable.map(assessment => {
            const index = availableAssessments.indexOf(assessment)
            return (
              <SimpleSelect.Option
                key={assessment._id}
                id={`peer-review-option-${index}`}
                value={String(index)}
              >
                {I18n.t('Peer Review (%{number} of %{total})', {
                  number: index + 1,
                  total: requiredPeerReviewCount,
                })}
              </SimpleSelect.Option>
            )
          })}
          {Array.from({length: unavailableCount}, (_, i) => {
            const reviewNumber = availableAssessments.length + i + 1
            const indexValue = availableAssessments.length + i
            return (
              <SimpleSelect.Option
                key={`unavailable-${i}`}
                id={`peer-review-unavailable-${i}`}
                value={String(indexValue)}
              >
                {I18n.t('Peer Review (%{number} of %{total})', {
                  number: reviewNumber,
                  total: requiredPeerReviewCount,
                })}
              </SimpleSelect.Option>
            )
          })}
        </SimpleSelect.Group>,
      )
    }

    return children
  }

  const totalOptionsCount = availableAssessments.length + unavailableCount
  const hasOptions = hasAssessments || unavailableCount > 0

  return (
    <SimpleSelect
      renderLabel={<ScreenReaderContent>{I18n.t('Select peer to review')}</ScreenReaderContent>}
      value={
        hasOptions
          ? String(selectedIndex >= 0 && selectedIndex < totalOptionsCount ? selectedIndex : 0)
          : 'no-peer-reviews'
      }
      onChange={handleChange}
      data-testid="peer-review-selector"
      width="15rem"
      assistiveText={I18n.t('Use arrow keys to navigate options. Press Enter to select.')}
    >
      {renderChildren()}
    </SimpleSelect>
  )
}
