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
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Spinner} from '@instructure/ui-spinner'
import {GradeDisplay} from './GradeDisplay'
import {RubricSection} from './RubricSection'
import {FeedbackSection} from './FeedbackSection'
import type {RecentGradeSubmission} from '../../../types'
import {useWidgetDashboard} from '../../../hooks/useWidgetDashboardContext'
import {useSubmissionDetails} from '../../../hooks/useSubmissionDetails'
import {useResponsiveContext} from '../../../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

interface ExpandedGradeViewProps {
  submission: RecentGradeSubmission
}

export const ExpandedGradeView: React.FC<ExpandedGradeViewProps> = ({submission}) => {
  const {sharedCourseData} = useWidgetDashboard()
  const {isMobile} = useResponsiveContext()
  const assignmentUrl = submission.assignment.htmlUrl
  const courseId = submission.assignment.course._id
  const assignmentName = submission.assignment.name
  const courseName = submission.assignment.course.name

  const courseData = sharedCourseData.find(course => course.courseId === courseId)
  const courseGrade = courseData?.currentGrade ?? null

  const {data: submissionDetails, isLoading, error} = useSubmissionDetails(submission._id)

  const rubricAssessment = submissionDetails?.rubricAssessments?.[0] || null
  const comments = submissionDetails?.comments || []
  const totalCommentsCount = submissionDetails?.totalCommentsCount || 0

  return (
    <View
      as="div"
      padding={isMobile ? 'none' : '0 medium medium medium'}
      data-testid={`expanded-grade-view-${submission._id}`}
    >
      <Flex direction="column" gap="small">
        <Flex.Item>
          <GradeDisplay
            score={submission.score}
            pointsPossible={submission.assignment.pointsPossible}
            grade={submission.grade}
            excused={submission.excused}
            gradingType={submission.assignment.gradingType}
            courseGrade={courseGrade}
            submissionId={submission._id}
          />
        </Flex.Item>

        <Flex.Item>
          <Flex direction={isMobile ? 'column' : 'row'} alignItems="start">
            <Flex.Item width={isMobile ? '100%' : '60%'} wrap="wrap">
              <Flex direction="column" gap="x-small" padding="x-small">
                {isLoading ? (
                  <Flex.Item>
                    <Spinner
                      renderTitle={I18n.t('Loading submission details')}
                      size="small"
                      data-testid={`submission-details-loading-${submission._id}`}
                    />
                  </Flex.Item>
                ) : error ? (
                  <Flex.Item>
                    <Text color="danger" data-testid={`submission-details-error-${submission._id}`}>
                      {I18n.t('Error loading submission details')}
                    </Text>
                  </Flex.Item>
                ) : (
                  <>
                    {rubricAssessment && (
                      <Flex.Item>
                        <RubricSection
                          rubricAssessment={rubricAssessment}
                          submissionId={submission._id}
                        />
                      </Flex.Item>
                    )}
                    <Flex.Item>
                      <FeedbackSection
                        comments={comments}
                        submissionId={submission._id}
                        totalCommentsCount={totalCommentsCount}
                        assignmentUrl={assignmentUrl}
                        assignmentName={assignmentName}
                      />
                    </Flex.Item>
                  </>
                )}
              </Flex>
            </Flex.Item>

            <Flex.Item width={isMobile ? '100%' : '40%'} wrap="wrap" padding="0 0 0 medium">
              <Flex direction="column" gap="x-small" padding="x-small">
                <Flex.Item overflowY="visible">
                  <Link
                    href={assignmentUrl}
                    isWithinText={false}
                    data-testid={`open-assignment-link-${submission._id}`}
                  >
                    {I18n.t('View %{assignmentName}', {assignmentName})}
                  </Link>
                </Flex.Item>
                <Flex.Item overflowY="visible">
                  <Link
                    href={`/courses/${courseId}/grades`}
                    isWithinText={false}
                    data-testid={`open-whatif-link-${submission._id}`}
                  >
                    {I18n.t('View %{assignmentName} what-if grading tool', {assignmentName})}
                  </Link>
                </Flex.Item>
                <Flex.Item overflowY="visible">
                  <Link
                    href={`/conversations?context_id=course_${courseId}&compose=true`}
                    isWithinText={false}
                    data-testid={`message-instructor-link-${submission._id}`}
                  >
                    {I18n.t('Message %{courseName} Instructor', {courseName})}
                  </Link>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}
