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
import {colors} from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'
import {SelfAssessmentComment} from './SelfAssessmentComment'
import {Flex} from '@instructure/ui-flex'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {CriteriaReadonlyComment} from './CriteriaReadonlyComment'
import {
  RubricAssessmentData,
  RubricCriterion,
  RubricSubmissionUser,
  UpdateAssessmentData,
} from '../types/rubric'
import {FC} from 'react'

const I18n = createI18nScope('rubrics-assessment-tray')

type TraditionalViewCriterionCommentProps = {
  colCount: number
  commentText: string
  criterion: RubricCriterion
  criterionSelfAssessment?: RubricAssessmentData
  isLastIndex: boolean
  isPreviewMode: boolean
  submissionUser?: RubricSubmissionUser
  setCommentText: React.Dispatch<React.SetStateAction<string>>
  updateAssessmentData: (params: Partial<UpdateAssessmentData>) => void
}

export const TraditionalViewCriterionComment: FC<TraditionalViewCriterionCommentProps> = ({
  colCount,
  commentText,
  criterion,
  criterionSelfAssessment,
  isLastIndex,
  isPreviewMode,
  submissionUser,
  setCommentText,
  updateAssessmentData,
}) => {
  return (
    <tr>
      <View
        as="td"
        colSpan={colCount}
        padding="x-small small"
        borderWidth={`small 0 ${isLastIndex ? 0 : 'small'} 0`}
        borderColor={colors.primitives.grey14}
        aria-label={`${I18n.t('Criterion comments for')} ${criterion.description}`}
      >
        <View as="div" padding="0" width="100%">
          <SelfAssessmentComment
            margin="0 0 small 0"
            selfAssessment={criterionSelfAssessment}
            user={submissionUser}
            submittedAtAlignment="start"
          />
          <Flex>
            {isPreviewMode ? (
              <Flex.Item shouldGrow={true}>
                <CriteriaReadonlyComment commentText={commentText} />
              </Flex.Item>
            ) : (
              <>
                <Flex.Item shouldGrow={true}>
                  <TextArea
                    label={I18n.t('Comment')}
                    placeholder={I18n.t('Leave a comment')}
                    data-testid={`comment-text-area-${criterion.id}`}
                    width="100%"
                    value={commentText}
                    onChange={e => setCommentText(e.target.value)}
                    onBlur={e => updateAssessmentData({comments: e.target.value})}
                  />
                </Flex.Item>
                <Flex.Item>
                  <View margin="0 0 0 small" themeOverride={{marginSmall: '1rem'}}>
                    <Button
                      color="secondary"
                      onClick={() => {
                        setCommentText('')
                        updateAssessmentData({comments: ''})
                      }}
                      data-testid={`clear-comment-button-${criterion.id}`}
                    >
                      {I18n.t('Clear')}
                    </Button>
                  </View>
                </Flex.Item>
              </>
            )}
          </Flex>
        </View>
      </View>
    </tr>
  )
}
