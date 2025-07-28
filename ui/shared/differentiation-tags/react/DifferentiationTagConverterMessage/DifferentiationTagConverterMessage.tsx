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
import {Spinner} from '@instructure/ui-spinner'
import axios from 'axios'
import {useState} from 'react'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('differentiation_tags')

export const CONVERT_DIFF_TAGS_BUTTON = 'convert-differentiation-tags-button'
export const CONVERT_DIFF_TAGS_MESSAGE = 'convert-differentiation-tags-message'

interface DifferentiationTagConverterMessageProps {
  courseId: string
  learningObjectType: string
  learningObjectId: string
  onFinish: () => void
}

const DifferentiationTagConverterMessage = ({
  courseId,
  learningObjectType,
  learningObjectId,
  onFinish,
}: DifferentiationTagConverterMessageProps) => {
  const [isLoading, setIsLoading] = useState(false)

  const getObjectTypeForMessage = () => {
    switch (learningObjectType) {
      case 'discussion':
      case 'discussion_topic':
        return 'discussion'
      case 'page':
      case 'wiki_page':
        return 'page'
      default:
        return learningObjectType
    }
  }

  const message = I18n.t(
    'This %{lo_type} was previously assigned via differentiation tag. To make any edits to this assignment you must convert differentiation tags to individual tags.',
    {lo_type: getObjectTypeForMessage()},
  )

  const getLearningObjectUrl = () => {
    switch (learningObjectType) {
      case 'module':
        return `/api/v1/courses/${courseId}/modules/${learningObjectId}/assignment_overrides/convert_tag_overrides`
      case 'assignment':
        return `/api/v1/courses/${courseId}/assignments/${learningObjectId}/date_details/convert_tag_overrides`
      case 'quiz':
        return `/api/v1/courses/${courseId}/quizzes/${learningObjectId}/date_details/convert_tag_overrides`
      case 'discussion':
      case 'discussion_topic':
        return `/api/v1/courses/${courseId}/discussion_topics/${learningObjectId}/date_details/convert_tag_overrides`
      case 'wiki_page':
      case 'page':
        return `/api/v1/courses/${courseId}/pages/${learningObjectId}/date_details/convert_tag_overrides`
      default:
        throw new Error(`Unsupported learning object type: ${learningObjectType}`)
    }
  }

  const displayFlashError = () => {
    showFlashAlert({
      type: 'error',
      message: I18n.t('Failed to convert differentiation tags.'),
    })
  }

  const convertTagOverrides = async () => {
    const url = getLearningObjectUrl()
    let response

    try {
      setIsLoading(true)
      response = await axios.put(url)
      setIsLoading(false)

      if (response.status === 204) {
        onFinish()
      } else {
        displayFlashError()
      }
    } catch (error) {
      setIsLoading(false)
      displayFlashError()
    }
  }

  return (
    <Alert
      variant="warning"
      hasShadow={false}
      margin="0 0 medium 0"
      data-testid="differentiation-tag-converter-message"
    >
      <Flex direction="column">
        <Text id={CONVERT_DIFF_TAGS_MESSAGE}>{message}</Text>
        <View as="div">
          <Button
            id={CONVERT_DIFF_TAGS_BUTTON}
            onClick={convertTagOverrides}
            color="primary"
            margin="small 0 0 0"
            disabled={isLoading}
            data-testid={CONVERT_DIFF_TAGS_BUTTON}
          >
            {I18n.t('Convert Differentiation Tags')}
          </Button>
          {isLoading && (
            <Spinner
              renderTitle={I18n.t('Converting Tag Overrides')}
              size="x-small"
              margin="small small 0 small"
            />
          )}
        </View>
      </Flex>
    </Alert>
  )
}

export default DifferentiationTagConverterMessage
