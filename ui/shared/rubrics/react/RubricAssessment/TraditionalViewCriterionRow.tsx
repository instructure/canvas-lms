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

import {FC, useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {possibleString} from '../Points'
import type {
  RubricAssessmentData,
  RubricCriterion,
  RubricSubmissionUser,
  UpdateAssessmentData,
} from '../types/rubric'
import {OutcomeTag} from './OutcomeTag'
import {LongDescriptionModal} from './LongDescriptionModal'
import {Link} from '@instructure/ui-link'
import {TraditionalViewCriterionComment} from './TraditionalViewCriterionComment'
import {TraditionalViewFreeFormComment} from './TraditionalViewFreeFormComment'
import {TraditionalViewCriterionPoints} from './TraditionalViewCriterionPoints'
import {TraditionalViewCriterionRatings} from './TraditionalViewCriterionRatings'
import {colors, borders} from '@instructure/canvas-theme'

const I18n = createI18nScope('rubrics-assessment-tray')

type TraditionalViewCriterionRowProps = {
  colCount: number
  criterion: RubricCriterion
  criterionAssessment?: RubricAssessmentData
  criterionSelfAssessment?: RubricAssessmentData
  hidePoints: boolean
  isFreeFormCriterionComments: boolean
  isLastIndex: boolean
  isPeerReview?: boolean
  isPreviewMode: boolean
  ratingOrder: string
  ratingsColumnMinWidth: number
  rubricSavedComments: string[]
  shouldFocusFirstRating?: boolean
  submissionUser?: RubricSubmissionUser
  validationErrors?: string[]
  onUpdateAssessmentData: (params: UpdateAssessmentData) => void
}
export const TraditionalViewCriterionRow: FC<TraditionalViewCriterionRowProps> = ({
  colCount,
  criterion,
  criterionAssessment,
  criterionSelfAssessment,
  hidePoints,
  isFreeFormCriterionComments,
  isLastIndex,
  isPeerReview,
  isPreviewMode,
  ratingOrder,
  ratingsColumnMinWidth,
  rubricSavedComments,
  shouldFocusFirstRating = false,
  submissionUser,
  validationErrors,
  onUpdateAssessmentData,
}) => {
  const [commentText, setCommentText] = useState<string>(criterionAssessment?.comments ?? '')
  const [isLongDescriptionOpen, setIsLongDescriptionOpen] = useState(false)
  const [pointTextInput, setPointTextInput] = useState('')

  const hasValidationError = validationErrors?.includes(criterion.id)

  const updateAssessmentData = (params: Partial<UpdateAssessmentData>) => {
    const updatedCriterionAssessment: UpdateAssessmentData = {
      ...criterionAssessment,
      ratingId: criterionAssessment?.id,
      ...params,
      criterionId: criterion.id,
    }
    onUpdateAssessmentData(updatedCriterionAssessment)
  }

  const hideComments =
    isFreeFormCriterionComments || (isPreviewMode && !criterionAssessment?.comments?.length)

  useEffect(() => {
    setCommentText(criterionAssessment?.comments ?? '')
    setPointTextInput(criterionAssessment?.points?.toString() ?? '')
  }, [criterionAssessment, isFreeFormCriterionComments])

  return (
    <>
      <tr
        style={{
          borderWidth: isLastIndex ? '0' : `${borders.widthSmall} 0`,
          borderBottomColor: colors.primitives.grey14,
          borderBottomStyle: 'solid',
        }}
      >
        <td
          style={{
            height: '100%',
            verticalAlign: 'top',
            padding: '0',
            maxWidth: '11.25rem',
          }}
        >
          <Flex as="div" direction="column" alignItems="stretch" padding="x-small small">
            {criterion.learningOutcomeId && (
              <View as="div" margin="0 0 small 0">
                <OutcomeTag displayName={criterion.description} />
              </View>
            )}
            <View as="div">
              <Text weight="bold">{criterion.outcome?.displayName || criterion.description}</Text>
            </View>
            <View as="div" margin="small 0 0 0">
              {criterion.longDescription?.trim() && (
                <>
                  <Link onClick={() => setIsLongDescriptionOpen(true)} display="block">
                    <Text size="x-small">{I18n.t('view longer description')}</Text>
                  </Link>
                  <LongDescriptionModal
                    longDescription={criterion.longDescription}
                    onClose={() => setIsLongDescriptionOpen(false)}
                    open={isLongDescriptionOpen}
                  />
                </>
              )}
            </View>
            {criterion.learningOutcomeId && (
              <View as="div" margin="xxx-small 0 0 0">
                <Text size="small">
                  {I18n.t('Threshold: %{threshold}', {
                    threshold: possibleString(criterion.masteryPoints),
                  })}
                </Text>
              </View>
            )}
          </Flex>
        </td>
        {isFreeFormCriterionComments ? (
          <TraditionalViewFreeFormComment
            commentText={commentText}
            criterion={criterion}
            hasValidationError={hasValidationError}
            hidePoints={hidePoints}
            isPeerReview={isPeerReview}
            isPreviewMode={isPreviewMode}
            minWidth="25.5rem"
            rubricSavedComments={rubricSavedComments}
            setCommentText={setCommentText}
            updateAssessmentData={updateAssessmentData}
          />
        ) : (
          <TraditionalViewCriterionRatings
            criterion={criterion}
            criterionAssessment={criterionAssessment}
            criterionSelfAssessment={criterionSelfAssessment}
            hasValidationError={hasValidationError}
            hidePoints={hidePoints}
            isPreviewMode={isPreviewMode}
            ratingOrder={ratingOrder}
            ratingsColumnMinWidth={ratingsColumnMinWidth}
            shouldFocusFirstRating={shouldFocusFirstRating}
            updateAssessmentData={updateAssessmentData}
          />
        )}
        {!hidePoints && (
          <TraditionalViewCriterionPoints
            criterion={criterion}
            isPreviewMode={isPreviewMode}
            pointTextInput={pointTextInput}
            possibleString={possibleString}
            setPointTextInput={setPointTextInput}
            updateAssessmentData={updateAssessmentData}
          />
        )}
      </tr>
      {!hideComments && (
        <TraditionalViewCriterionComment
          colCount={colCount}
          commentText={commentText}
          criterion={criterion}
          criterionSelfAssessment={criterionSelfAssessment}
          isLastIndex={isLastIndex}
          isPreviewMode={isPreviewMode}
          submissionUser={submissionUser}
          setCommentText={setCommentText}
          updateAssessmentData={updateAssessmentData}
        />
      )}
    </>
  )
}
