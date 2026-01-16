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

const I18n = createI18nScope('widget_dashboard')

interface GradeDisplayProps {
  grade: string | null
  courseGrade: number | null
  submissionId: string
}

export const GradeDisplay: React.FC<GradeDisplayProps> = ({grade, courseGrade, submissionId}) => {
  // TODO: update to handle all possible grade formats
  const assignmentGradeText = grade || I18n.t('No grade')
  const courseGradeText =
    courseGrade !== null ? I18n.t('%{grade}%', {grade: courseGrade}) : I18n.t('N/A')

  return (
    <View
      as="div"
      display="block"
      margin="x-small"
      background="primary"
      padding="small"
      borderRadius="large"
      shadow="above"
      data-testid={`grade-display-${submissionId}`}
    >
      <Flex direction="column" gap="small" alignItems="center" justifyItems="center">
        <Flex.Item>
          <Text size="x-large" weight="bold" data-testid={`grade-percentage-${submissionId}`}>
            {assignmentGradeText}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Text size="small" color="secondary" data-testid={`course-grade-label-${submissionId}`}>
            {I18n.t('Course grade: %{courseGrade}', {courseGrade: courseGradeText})}
          </Text>
        </Flex.Item>
      </Flex>
    </View>
  )
}
