// @ts-nocheck
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Assignment, AssessmentRequest} from '../../../api.d'

const I18n = useI18nScope('assignment')

type StudentPeerUrlQueryParams = {
  anonymous_asset_id?: string
  reviewee_id?: string
}

export type AssignmentPeerReview = Pick<
  Assignment,
  'id' | 'course_id' | 'anonymous_peer_reviews' | 'assessment_requests' | 'name'
>

export type StudentViewPeerReviewsProps = {
  assignment: AssignmentPeerReview
}

type PeerReviewProps = {
  assignment: AssignmentPeerReview
  assessment: AssessmentRequest
  index: number
}

export const StudentViewPeerReviews = ({assignment}: StudentViewPeerReviewsProps) => {
  return (
    <>
      {assignment.assessment_requests.map((assessment, idx) => (
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

const PeerReview = ({assessment, assignment, index}: PeerReviewProps) => {
  const title = I18n.t(`Required Peer Review %{index}`, {index: index + 1})
  const {name: assignmentName} = assignment
  const screenreaderLabel = I18n.t('%{title} for %{assignmentName}', {title, assignmentName})
  const revieweeUsername = !assessment.available
    ? I18n.t('Not Available')
    : assignment?.anonymous_peer_reviews
    ? I18n.t('Anonymous Student')
    : assessment.user_name

  const {workflow_state} = assessment

  const studentPeerReviewUrl = () => {
    const {anonymous_peer_reviews, course_id, id} = assignment
    const {anonymous_id, user_id} = assessment

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
              {workflow_state === 'completed' ? <IconPeerGradedLine /> : <IconPeerReviewLine />}
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
              <div className="ig-details__item">{revieweeUsername}</div>
            </div>
          </div>
        </div>
      </div>
    </li>
  )
}
