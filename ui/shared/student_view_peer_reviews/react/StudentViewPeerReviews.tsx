/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {IconArrowNestLine, IconPeerReviewLine, IconPeerGradedLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {dateString} from '@canvas/datetime/date-functions'
import type {Assignment, AssessmentRequest} from '../../../api.d'

const I18n = createI18nScope('assignment')

type StudentPeerUrlQueryParams = {
  anonymous_asset_id?: string
  reviewee_id?: string
}

export type AssignmentPeerReview = Pick<
  Assignment,
  'id' | 'course_id' | 'anonymous_peer_reviews' | 'assessment_requests' | 'name'
> & {
  peer_review_count?: number | null
  peer_review_points_possible?: number | null
  peer_review_due_at?: string | null
}

export type StudentViewPeerReviewsProps = {
  assignment: AssignmentPeerReview
}

type PeerReviewProps = {
  assignment: AssignmentPeerReview
  assessment?: AssessmentRequest
  index?: number
  isSubAssignment?: boolean
}

export const StudentViewPeerReviews = ({assignment}: StudentViewPeerReviewsProps) => {
  if (ENV.FEATURES.peer_review_allocation_and_grading) {
    return <PeerReview assignment={assignment} isSubAssignment />
  }

  return (
    <>
      {assignment.assessment_requests?.map((assessment, idx) => (
        <PeerReview
          assessment={assessment}
          index={idx}
          assignment={assignment}
          key={`${assignment.id}_${assessment.user_id ?? assessment.anonymous_id}`}
        />
      ))}
    </>
  )
}

const PeerReview = ({assessment, assignment, index, isSubAssignment}: PeerReviewProps) => {
  const {
    name: assignmentName,
    course_id,
    id,
    peer_review_count,
    peer_review_points_possible,
    peer_review_due_at,
  } = assignment

  const title = isSubAssignment
    ? I18n.t('%{assignmentName} Peer Reviews (%{count})', {
        assignmentName,
        count: peer_review_count ?? 0,
      })
    : I18n.t(`Required Peer Review %{index}`, {index: (index ?? 0) + 1})

  const screenreaderLabel = isSubAssignment
    ? title
    : I18n.t('%{title} for %{assignmentName}', {title, assignmentName})

  const getRevieweeUsername = () => {
    if (isSubAssignment || !assessment) return null
    if (!assessment.available) return I18n.t('Not Available')
    if (assignment?.anonymous_peer_reviews) return I18n.t('Anonymous Student')
    return assessment.user_name
  }

  const dueDateDisplay =
    isSubAssignment && peer_review_due_at ? dateString(peer_review_due_at) : null

  const pointsDisplay =
    isSubAssignment && peer_review_points_possible != null
      ? I18n.t('%{points} pts', {points: peer_review_points_possible})
      : null

  const workflow_state = assessment?.workflow_state

  const studentPeerReviewUrl = () => {
    if (isSubAssignment) {
      return `/courses/${course_id}/assignments/${id}/peer_reviews`
    }

    const {anonymous_peer_reviews} = assignment
    const {anonymous_id, user_id} = assessment!

    const queryParams: StudentPeerUrlQueryParams = anonymous_peer_reviews
      ? {anonymous_asset_id: anonymous_id}
      : {reviewee_id: user_id}
    return `/courses/${course_id}/assignments/${id}?${new URLSearchParams(queryParams)}`
  }

  return (
    <li className="context_module_item student-view cannot-duplicate indent_1">
      <div className="ig-row">
        <div className="ig-row__layout">
          <span
            className="type_icon display_icons"
            title={title}
            role="none"
            style={{fontSize: '1.125rem'}}
          >
            <View as="span" margin="0 0 0 medium">
              <IconArrowNestLine />
            </View>
            <View as="span" margin="0 0 0 small">
              {isSubAssignment || workflow_state !== 'completed' ? (
                <IconPeerReviewLine />
              ) : (
                <IconPeerGradedLine />
              )}
            </View>
          </span>
          <div className="ig-info">
            <div className="module-item-title">
              <span className="item_name">
                <a
                  aria-label={screenreaderLabel}
                  className="ig-title title item_link"
                  href={studentPeerReviewUrl()}
                >
                  {title}
                </a>
              </span>
            </div>
            <div className="ig-details">
              {getRevieweeUsername() && (
                <div className="ig-details__item">{getRevieweeUsername()}</div>
              )}
              {dueDateDisplay && (
                <View margin="0 x-small 0 0">
                  <Text className="due_date_display ig-details__item" size="legend">
                    {dueDateDisplay}
                  </Text>
                </View>
              )}
              {pointsDisplay && (
                <Text className="points_possible_display ig-details__item" size="legend">
                  {pointsDisplay}
                </Text>
              )}
            </div>
          </div>
        </div>
      </div>
    </li>
  )
}
