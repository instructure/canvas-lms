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
import CourseProgressBar from './CourseProgressBar'
import type {CourseProgress} from '../../../hooks/useProgressOverview'

const I18n = createI18nScope('widget_dashboard')

interface CourseProgressItemProps {
  course: CourseProgress
}

const CourseProgressItem: React.FC<CourseProgressItemProps> = ({course}) => {
  const {
    courseId,
    courseName,
    submittedAndGradedCount,
    submittedNotGradedCount,
    missingSubmissionsCount,
    submissionsDueCount,
  } = course

  return (
    <View
      as="div"
      padding="small"
      borderWidth="0 0 small 0"
      data-testid={`course-progress-item-${courseId}`}
    >
      <Flex direction="column" gap="small">
        <Flex.Item overflowY="visible">
          <Flex direction="column" gap="x-small">
            <Flex.Item>
              <Text size="medium" weight="bold">
                {courseName}
              </Text>
            </Flex.Item>
            <Flex.Item overflowY="visible">
              <Link
                href={`/courses/${courseId}`}
                isWithinText={false}
                aria-label={I18n.t('Go to %{courseName}', {courseName})}
                data-testid={`course-link-${courseId}`}
              >
                <Text size="small">{I18n.t('Go to course')}</Text>
              </Link>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <CourseProgressBar
            submittedAndGradedCount={submittedAndGradedCount}
            submittedNotGradedCount={submittedNotGradedCount}
            missingSubmissionsCount={missingSubmissionsCount}
            submissionsDueCount={submissionsDueCount}
            courseId={courseId}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default CourseProgressItem
