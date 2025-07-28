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

import {useState, FC, Dispatch, SetStateAction} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {CommentLibrary} from './CommentLibrary'
import {RubricAssessmentData, RubricCriterion, UpdateAssessmentData} from '../types/rubric'

const I18n = createI18nScope('rubrics-assessment-tray')

export type TraditionalViewFreeFormCommentProps = {
  commentText: string
  criterion: RubricCriterion
  criterionSelfAssessment?: RubricAssessmentData
  hasValidationError?: boolean
  hidePoints: boolean
  isPeerReview?: boolean
  isPreviewMode: boolean
  minWidth: string
  rubricSavedComments: string[]
  setCommentText: Dispatch<SetStateAction<string>>
  updateAssessmentData: (params: Partial<UpdateAssessmentData>) => void
}

export const TraditionalViewFreeFormComment: FC<TraditionalViewFreeFormCommentProps> = ({
  commentText,
  criterion,
  hasValidationError,
  hidePoints,
  isPeerReview,
  isPreviewMode,
  minWidth,
  rubricSavedComments,
  setCommentText,
  updateAssessmentData,
}) => {
  const [isSaveCommentChecked, setIsSaveCommentChecked] = useState(false)

  return (
    <View
      as="td"
      padding={`x-small small`}
      borderWidth={hasValidationError ? 'medium' : `small ${hidePoints ? 0 : 'small'} 0 small`}
      borderColor={hasValidationError ? 'danger' : 'primary'}
      borderRadius={hasValidationError ? 'medium' : 'small'}
      minWidth={minWidth}
    >
      <View as="div" minWidth={minWidth}>
        <Flex direction="column">
          {!isPreviewMode && !isPeerReview && rubricSavedComments.length > 0 && (
            <>
              <Flex.Item>
                <Text weight="bold">{I18n.t('Comment Library')}</Text>
              </Flex.Item>
              <Flex.Item margin="x-small 0 0 0" shouldGrow={true}>
                <CommentLibrary
                  rubricSavedComments={rubricSavedComments}
                  criterionId={criterion.id}
                  setCommentText={setCommentText}
                  updateAssessmentData={updateAssessmentData}
                />
              </Flex.Item>
            </>
          )}
          <Flex.Item margin={rubricSavedComments.length > 0 ? 'medium 0 0 0' : '0 0 0 0'}>
            <Text weight="bold">{I18n.t('Comment')}</Text>
          </Flex.Item>
          <Flex.Item margin="x-small 0 0 0" shouldGrow={true} overflowX="hidden" overflowY="hidden">
            {isPreviewMode ? (
              <View as="div" margin="0 0 0 0">
                {/* The "pre-wrap" style is necessary to preserve white spaces in submitted
                      comments. However, it could not be directly assigned to the <Text />
                      component, so a <span /> child element was added instead. */}
                <Text>
                  <span style={{whiteSpace: 'pre-wrap'}}>{commentText}</span>
                </Text>
              </View>
            ) : (
              <TextArea
                label={<ScreenReaderContent>{I18n.t('Criterion Comment')}</ScreenReaderContent>}
                data-testid={`free-form-comment-area-${criterion.id}`}
                width="100%"
                height="38px"
                value={commentText}
                onChange={e => setCommentText(e.target.value)}
                onBlur={e => updateAssessmentData({comments: e.target.value})}
              />
            )}
          </Flex.Item>
          {!isPeerReview && !isPreviewMode && (
            <Flex.Item margin="medium 0 x-small 0" shouldGrow={true}>
              <Checkbox
                checked={isSaveCommentChecked}
                label={I18n.t('Save this comment for reuse')}
                size="small"
                data-testid={`save-comment-checkbox-${criterion.id}`}
                onChange={e => {
                  updateAssessmentData({saveCommentsForLater: !!e.target.checked})
                  setIsSaveCommentChecked(!!e.target.checked)
                }}
              />
            </Flex.Item>
          )}
        </Flex>
      </View>
    </View>
  )
}
