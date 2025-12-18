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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'

export interface CourseProgressBarProps {
  submittedAndGradedCount: number
  submittedNotGradedCount: number
  missingSubmissionsCount: number
  submissionsDueCount: number
  courseId: string
}

export interface ProgressSegment {
  color: string
  percentage: number
  label: string
  testId: string
}

export function calculateProgressSegments(
  submittedAndGradedCount: number,
  submittedNotGradedCount: number,
  missingSubmissionsCount: number,
  submissionsDueCount: number,
): ProgressSegment[] {
  const total =
    submittedAndGradedCount +
    submittedNotGradedCount +
    missingSubmissionsCount +
    submissionsDueCount

  if (total === 0) {
    return [
      {
        color: '#D8E7F3',
        percentage: 100,
        label: 'No assignments',
        testId: 'no-assignments',
      },
    ]
  }

  const segments: ProgressSegment[] = []

  if (submittedAndGradedCount > 0) {
    segments.push({
      color: '#1E9975',
      percentage: (submittedAndGradedCount / total) * 100,
      label: 'Submitted and graded',
      testId: 'graded',
    })
  }

  if (submittedNotGradedCount > 0) {
    segments.push({
      color: '#2573DF',
      percentage: (submittedNotGradedCount / total) * 100,
      label: 'Submitted not graded',
      testId: 'not-graded',
    })
  }

  if (missingSubmissionsCount > 0) {
    segments.push({
      color: '#DB6414',
      percentage: (missingSubmissionsCount / total) * 100,
      label: 'Missing',
      testId: 'missing',
    })
  }

  if (submissionsDueCount > 0) {
    segments.push({
      color: '#D8E7F3',
      percentage: (submissionsDueCount / total) * 100,
      label: 'Due',
      testId: 'due',
    })
  }

  return segments
}

const CourseProgressBar: React.FC<CourseProgressBarProps> = ({
  submittedAndGradedCount,
  submittedNotGradedCount,
  missingSubmissionsCount,
  submissionsDueCount,
  courseId,
}) => {
  const segments = calculateProgressSegments(
    submittedAndGradedCount,
    submittedNotGradedCount,
    missingSubmissionsCount,
    submissionsDueCount,
  )

  return (
    <View as="div" height="24px" width="100%" data-testid={`progress-bar-${courseId}`}>
      <Flex height="100%" width="100%">
        {segments.map((segment, index) => (
          <Flex.Item
            key={`${segment.testId}-${index}`}
            size={`${segment.percentage}%`}
            height="100%"
            padding={index < segments.length - 1 ? '0 xx-small 0 0' : undefined}
          >
            <View
              as="div"
              height="100%"
              width="100%"
              background="primary"
              themeOverride={{
                backgroundPrimary: segment.color,
              }}
              borderRadius={
                index === 0 && index === segments.length - 1
                  ? 'medium'
                  : index === 0
                    ? 'medium 0 0 medium'
                    : index === segments.length - 1
                      ? '0 medium medium 0'
                      : undefined
              }
              data-testid={`progress-segment-${segment.testId}-${courseId}`}
            />
          </Flex.Item>
        ))}
      </Flex>
    </View>
  )
}

export default CourseProgressBar
