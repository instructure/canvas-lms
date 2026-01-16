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
import {Button} from '@instructure/ui-buttons'
import {GradeDisplay} from './GradeDisplay'
import type {RecentGradeSubmission} from '../../../types'
import {useWidgetDashboard} from '../../../hooks/useWidgetDashboardContext'

const I18n = createI18nScope('widget_dashboard')

interface ExpandedGradeViewProps {
  submission: RecentGradeSubmission
}

export const ExpandedGradeView: React.FC<ExpandedGradeViewProps> = ({submission}) => {
  const {sharedCourseData} = useWidgetDashboard()
  const assignmentUrl = submission.assignment.htmlUrl
  const courseId = submission.assignment.course._id

  const courseData = sharedCourseData.find(course => course.courseId === courseId)
  const courseGrade = courseData?.currentGrade ?? null

  return (
    <View
      as="div"
      padding="0 medium medium medium"
      data-testid={`expanded-grade-view-${submission._id}`}
    >
      <Flex direction="column" gap="small">
        <Flex.Item>
          <GradeDisplay
            grade={submission.grade}
            courseGrade={courseGrade}
            submissionId={submission._id}
          />
        </Flex.Item>

        <Flex.Item>
          <Flex direction="row" gap="medium" alignItems="start">
            <Flex.Item shouldGrow shouldShrink>
              <Flex direction="column" gap="x-small" padding="x-small">
                <Flex.Item>
                  <Text
                    weight="bold"
                    size="large"
                    data-testid={`rubric-section-heading-${submission._id}`}
                  >
                    {I18n.t('Rubric')}
                  </Text>
                </Flex.Item>
                <Flex.Item>
                  <Text color="secondary" data-testid={`rubric-placeholder-${submission._id}`}>
                    {I18n.t('Rubric details will be displayed here')}
                  </Text>
                </Flex.Item>

                <Flex.Item>
                  <Text
                    weight="bold"
                    size="large"
                    data-testid={`feedback-section-heading-${submission._id}`}
                  >
                    {I18n.t('Feedback')}
                  </Text>
                </Flex.Item>
                <Flex.Item>
                  <Text color="secondary" data-testid={`feedback-placeholder-${submission._id}`}>
                    {I18n.t('Feedback comments will be displayed here')}
                  </Text>
                </Flex.Item>
                <Flex.Item overflowY="visible">
                  <Button
                    color="primary-inverse"
                    size="medium"
                    data-testid={`view-inline-feedback-button-${submission._id}`}
                  >
                    {I18n.t('View inline feedback')}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item>
              <Flex direction="column" gap="x-small" padding="x-small">
                <Flex.Item overflowY="visible">
                  <Link
                    href={assignmentUrl}
                    isWithinText={false}
                    data-testid={`open-assignment-link-${submission._id}`}
                  >
                    {I18n.t('Open assignment')}
                  </Link>
                </Flex.Item>
                <Flex.Item overflowY="visible">
                  <Link
                    href={`/courses/${courseId}/grades`}
                    isWithinText={false}
                    data-testid={`open-whatif-link-${submission._id}`}
                  >
                    {I18n.t('Open what-if grading tool')}
                  </Link>
                </Flex.Item>
                <Flex.Item overflowY="visible">
                  <Link
                    href={`/conversations?context_id=course_${courseId}`}
                    isWithinText={false}
                    data-testid={`message-instructor-link-${submission._id}`}
                  >
                    {I18n.t('Message instructor')}
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
