/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {HorizontalButtonDisplay} from './HorizontalButtonDisplay'
import {VerticalButtonDisplay} from './VerticalButtonDisplay'
import type {RubricAssessmentData, RubricCriterion, UpdateAssessmentData} from '../types/rubric'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {CommentLibrary} from './CommentLibrary'
import {CriteriaReadonlyComment} from './CriteriaReadonlyComment'
import {
  findCriterionMatchingRatingIndex,
  htmlEscapeCriteriaLongDescription,
} from './utils/rubricUtils'
import {possibleString} from '../Points'
import {OutcomeTag} from './OutcomeTag'

const I18n = useI18nScope('rubrics-assessment-tray')

type ModernViewModes = 'horizontal' | 'vertical'

type ModernViewProps = {
  criteria: RubricCriterion[]
  hidePoints: boolean
  isPreviewMode: boolean
  isPeerReview: boolean
  isFreeFormCriterionComments: boolean
  ratingOrder: string
  rubricAssessmentData: RubricAssessmentData[]
  selectedViewMode: ModernViewModes
  rubricSavedComments?: Record<string, string[]>
  onUpdateAssessmentData: (params: UpdateAssessmentData) => void
}
export const ModernView = ({
  criteria,
  hidePoints,
  isPreviewMode,
  isPeerReview,
  isFreeFormCriterionComments,
  ratingOrder,
  rubricAssessmentData,
  selectedViewMode,
  rubricSavedComments,
  onUpdateAssessmentData,
}: ModernViewProps) => {
  return (
    <View as="div" margin="0" overflowX="hidden">
      {criteria.map((criterion, index) => {
        const criterionAssessment = rubricAssessmentData.find(
          data => data.criterionId === criterion.id
        )

        return (
          <CriterionRow
            key={criterion.id}
            criterion={criterion}
            displayHr={index < criteria.length - 1}
            hidePoints={hidePoints}
            isPreviewMode={isPreviewMode}
            isPeerReview={isPeerReview}
            ratingOrder={ratingOrder}
            criterionUseRange={criterion.criterionUseRange}
            criterionAssessment={criterionAssessment}
            selectedViewMode={selectedViewMode}
            rubricSavedComments={rubricSavedComments?.[criterion.id] ?? []}
            onUpdateAssessmentData={onUpdateAssessmentData}
            isFreeFormCriterionComments={isFreeFormCriterionComments}
          />
        )
      })}
    </View>
  )
}

type CriterionRowProps = {
  criterion: RubricCriterion
  displayHr: boolean
  hidePoints: boolean
  isPreviewMode: boolean
  isPeerReview: boolean
  isFreeFormCriterionComments: boolean
  ratingOrder: string
  criterionUseRange: boolean
  criterionAssessment?: RubricAssessmentData
  selectedViewMode: ModernViewModes
  rubricSavedComments: string[]
  onUpdateAssessmentData: (params: UpdateAssessmentData) => void
}
export const CriterionRow = ({
  criterion,
  displayHr,
  hidePoints,
  isPreviewMode,
  isPeerReview,
  isFreeFormCriterionComments,
  ratingOrder,
  criterionUseRange,
  criterionAssessment,
  selectedViewMode,
  rubricSavedComments,
  onUpdateAssessmentData,
}: CriterionRowProps) => {
  const {ratings} = criterion
  const selectedRatingIndex = findCriterionMatchingRatingIndex(
    criterion.ratings,
    criterionAssessment?.points,
    criterion.criterionUseRange
  )

  const [pointsInput, setPointsInput] = useState<string>()
  const [selectedRatingDescription, setSelectedRatingDescription] = useState<string>()
  const [commentText, setCommentText] = useState<string>(criterionAssessment?.comments ?? '')
  const [isSaveCommentChecked, setIsSaveCommentChecked] = useState(false)

  useEffect(() => {
    setCommentText(criterionAssessment?.comments ?? '')
    setPointsInput((criterionAssessment?.points ?? '').toString())
  }, [criterionAssessment])

  const updateAssessmentData = (params: Partial<UpdateAssessmentData>) => {
    const updatedCriterionAssessment: UpdateAssessmentData = {
      ...criterionAssessment,
      ...params,
      criterionId: criterion.id,
    }
    onUpdateAssessmentData(updatedCriterionAssessment)
  }

  const selectRating = (index: number) => {
    if (selectedRatingIndex === index) {
      updateAssessmentData({points: undefined})
      setPoints('')
      return
    }

    const selectedRating = ratings[index]
    setPoints(selectedRating?.points.toString() ?? '')
    setSelectedRatingDescription(selectedRating?.description)
  }

  const setPoints = (value: string) => {
    const points = Number(value)

    if (!value.trim().length || Number.isNaN(points)) {
      updateAssessmentData({points: undefined})
      setPointsInput('')
      return
    }

    updateAssessmentData({
      points,
      description: selectedRatingDescription,
    })
    setPointsInput(points.toString())
  }

  const renderButtonDisplay = () => {
    if (selectedViewMode === 'horizontal' && ratings.length <= 5) {
      return (
        <HorizontalButtonDisplay
          isPreviewMode={isPreviewMode}
          ratings={ratings}
          ratingOrder={ratingOrder}
          selectedRatingIndex={selectedRatingIndex}
          onSelectRating={selectRating}
          criterionUseRange={criterionUseRange}
        />
      )
    }

    return (
      <VerticalButtonDisplay
        isPreviewMode={isPreviewMode}
        ratings={ratings}
        ratingOrder={ratingOrder}
        selectedRatingIndex={selectedRatingIndex}
        onSelectRating={selectRating}
        criterionUseRange={criterionUseRange}
      />
    )
  }

  const pointsInputValue = pointsInput?.toString() ?? ''
  const totalPointsValue = criterion.points.toString()
  const instructorPointsText = I18n.t(
    'Instructor Points %{pointsInputValue} out of %{totalPointsValue}',
    {pointsInputValue, totalPointsValue}
  )

  return (
    <View as="div" margin="0 0 small 0">
      {!hidePoints && (
        <Flex data-testid="modern-view-out-of-points">
          <Flex.Item shouldGrow={true}>
            {criterion.learningOutcomeId && <OutcomeTag displayName={criterion.description} />}
          </Flex.Item>
          <Flex.Item margin={isPreviewMode ? '0 0 0 x-small' : '0'}>
            {isPreviewMode ? (
              <Text size="small" weight="bold" aria-label={instructorPointsText}>
                {pointsInputValue}
              </Text>
            ) : (
              <TextInput
                renderLabel={<ScreenReaderContent>{instructorPointsText}</ScreenReaderContent>}
                placeholder="--"
                width="3.375rem"
                height="2.375rem"
                data-testid={`criterion-score-${criterion.id}`}
                value={pointsInputValue}
                onChange={e => setPointsInput(e.target.value)}
                onBlur={e => setPoints(e.target.value)}
              />
            )}
          </Flex.Item>
          <Flex.Item margin={isPreviewMode ? '0' : '0 0 0 x-small'}>
            <Text size="small" weight="bold" aria-hidden={true}>
              /{criterion.points}
            </Text>
          </Flex.Item>
        </Flex>
      )}
      <View as="div">
        <Text size="medium" weight="bold">
          {criterion.outcome?.displayName || criterion.description}
        </Text>
      </View>
      <View as="div" margin="xx-small 0 0 0" themeOverride={{marginXxSmall: '.25rem'}}>
        <Text
          size="small"
          weight="normal"
          themeOverride={{fontSizeXSmall: '0.875rem', paragraphMargin: 0}}
          dangerouslySetInnerHTML={htmlEscapeCriteriaLongDescription(criterion)}
        />
      </View>
      {criterion.learningOutcomeId && (
        <View as="div" margin="xx-small 0 0 0">
          <Text>
            {I18n.t('Threshold: %{threshold}', {
              threshold: possibleString(criterion.masteryPoints),
            })}
          </Text>
        </View>
      )}
      <View as="div" margin="small 0 0 0">
        {!isFreeFormCriterionComments && renderButtonDisplay()}
      </View>
      <View as="div" margin="small 0 0 0" overflowX="hidden" overflowY="hidden">
        {isFreeFormCriterionComments ? (
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
            <Flex.Item
              margin="x-small 0 0 0"
              shouldGrow={true}
              overflowX="hidden"
              overflowY="hidden"
            >
              <TextArea
                label={<ScreenReaderContent>{I18n.t('Criterion Comment')}</ScreenReaderContent>}
                readOnly={isPreviewMode}
                data-testid={`free-form-comment-area-${criterion.id}`}
                width="100%"
                height="38px"
                value={commentText}
                onChange={e => setCommentText(e.target.value)}
                onBlur={e => updateAssessmentData({comments: e.target.value})}
              />
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
        ) : (
          <Flex direction="column">
            <Flex.Item
              margin="x-small 0 0 0"
              shouldGrow={true}
              overflowX="hidden"
              overflowY="hidden"
            >
              {isPreviewMode ? (
                <CriteriaReadonlyComment commentText={commentText} />
              ) : (
                <TextArea
                  label={I18n.t('Comment')}
                  size="small"
                  value={commentText}
                  onChange={e => setCommentText(e.target.value)}
                  onBlur={() => updateAssessmentData({comments: commentText})}
                  placeholder={I18n.t('Leave a comment')}
                  data-testid={`comment-text-area-${criterion.id}`}
                />
              )}
            </Flex.Item>
          </Flex>
        )}
      </View>
      {displayHr && <View as="hr" margin="medium 0" aria-hidden={true} />}
    </View>
  )
}
