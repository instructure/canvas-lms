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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('differentiation_tags')

interface ConversionMessageProps {
  onCourseConvertTags: () => void
}

const ConversionMessage = ({onCourseConvertTags}: ConversionMessageProps) => {
  const message = I18n.t(
    `Differentiation tags have been disabled for this course.
      Course content assigned via Differentiation Tags can't be edited until it's converted to individual student assignments.
      Click the button below to convert all affected items in the course.
      Every learning object in this course that is assigned via Differentiaiton Tag will be handled (assignments, quizzes, discussion topics, pages, and modules).`,
  )

  return (
    <Alert
      variant="warning"
      hasShadow={false}
      margin="0 0 medium 0"
      data-testid="course-differentiation-tag-converter-warning"
    >
      <Flex direction="column" justifyItems="start">
        <Text data-testid="course-tag-conversion-message">{message}</Text>
        <View as="div" width="25rem">
          <Button
            color="primary"
            margin="small 0 0 0"
            onClick={onCourseConvertTags}
            data-testid="course-tag-conversion-button"
          >
            {I18n.t('Convert Course Tags')}
          </Button>
        </View>
      </Flex>
    </Alert>
  )
}

export default ConversionMessage
