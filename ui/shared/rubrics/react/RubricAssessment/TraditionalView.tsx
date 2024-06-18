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
import {colors} from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {possibleString} from '../Points'
import type {RubricAssessmentData, RubricCriterion, UpdateAssessmentData} from '../types/rubric'
import {Grid} from '@instructure/ui-grid'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {CommentLibrary} from './CommentLibrary'
import {CriteriaReadonlyComment} from './CriteriaReadonlyComment'
import {Button} from '@instructure/ui-buttons'
import {escapeNewLineText, htmlEscapeCriteriaLongDescription} from './utils/rubricUtils'

const I18n = useI18nScope('rubrics-assessment-tray')
const {licorice} = colors

type TraditionalViewProps = {
  criteria: RubricCriterion[]
  hidePoints: boolean
  isPreviewMode: boolean
  isPeerReview?: boolean
  isFreeFormCriterionComments: boolean
  ratingOrder?: string
  rubricAssessmentData: RubricAssessmentData[]
  rubricTitle: string
  rubricSavedComments?: Record<string, string[]>
  onUpdateAssessmentData: (params: UpdateAssessmentData) => void
}
export const TraditionalView = ({
  criteria,
  hidePoints,
  isPreviewMode,
  isPeerReview,
  isFreeFormCriterionComments,
  ratingOrder = 'descending',
  rubricAssessmentData,
  rubricTitle,
  rubricSavedComments,
  onUpdateAssessmentData,
}: TraditionalViewProps) => {
  return (
    <View as="div" margin="0 0 small 0" data-testid="rubric-assessment-traditional-view">
      <View
        as="div"
        width="100%"
        background="secondary"
        borderWidth="small small 0 small"
        height="2.375rem"
        padding="x-small 0 0 small"
        themeOverride={{paddingXSmall: '0.438rem'}}
      >
        <Text weight="bold">{rubricTitle}</Text>
      </View>
      <Flex height="2.375rem">
        <Flex.Item width="11.25rem" height="2.375rem">
          <View
            as="div"
            background="secondary"
            borderWidth="small"
            height="100%"
            padding="x-small 0 0 small"
            themeOverride={{paddingXSmall: '0.438rem'}}
          >
            <Text weight="bold">{I18n.t('Criteria')}</Text>
          </View>
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <View
            as="div"
            background="secondary"
            borderWidth="small 0"
            height="2.375rem"
            padding="x-small 0 0 small"
          >
            {isFreeFormCriterionComments && <Text weight="bold">{I18n.t('Comments')}</Text>}
          </View>
        </Flex.Item>
        <Flex.Item width="8.875rem" height="2.375rem">
          <View
            as="div"
            background="secondary"
            borderWidth="small small small 0"
            height="2.375rem"
          />
        </Flex.Item>
        {!hidePoints && (
          <Flex.Item width="8.875rem" height="2.375rem">
            <View
              as="div"
              background="secondary"
              borderWidth="small small small 0"
              height="100%"
              padding="x-small 0 0 small"
              themeOverride={{paddingXSmall: '0.438rem'}}
            >
              <Text weight="bold">{I18n.t('Points')}</Text>
            </View>
          </Flex.Item>
        )}
      </Flex>

      {criteria.map((criterion, index) => {
        const criterionAssessment = rubricAssessmentData.find(
          data => data.criterionId === criterion.id
        )

        return (
          <CriterionRow
            // we use the array index because rating may not have an id
            /* eslint-disable-next-line react/no-array-index-key */
            key={`criterion-${criterion.id}-${index}`}
            criterion={criterion}
            criterionAssessment={criterionAssessment}
            ratingOrder={ratingOrder}
            rubricSavedComments={rubricSavedComments?.[criterion.id] ?? []}
            isPreviewMode={isPreviewMode}
            isPeerReview={isPeerReview}
            onUpdateAssessmentData={onUpdateAssessmentData}
            isFreeFormCriterionComments={isFreeFormCriterionComments}
            hidePoints={hidePoints}
          />
        )
      })}
    </View>
  )
}

type CriterionRowProps = {
  criterion: RubricCriterion
  criterionAssessment?: RubricAssessmentData
  hidePoints: boolean
  isPreviewMode: boolean
  isPeerReview?: boolean
  isFreeFormCriterionComments: boolean
  onUpdateAssessmentData: (params: UpdateAssessmentData) => void
  ratingOrder: string
  rubricSavedComments: string[]
}
const CriterionRow = ({
  criterion,
  criterionAssessment,
  hidePoints,
  isPreviewMode,
  isPeerReview,
  isFreeFormCriterionComments,
  onUpdateAssessmentData,
  ratingOrder,
  rubricSavedComments,
}: CriterionRowProps) => {
  const [hoveredRatingIndex, setHoveredRatingIndex] = useState<number>()
  const [commentText, setCommentText] = useState<string>(criterionAssessment?.comments ?? '')
  const [isSaveCommentChecked, setIsSaveCommentChecked] = useState(false)

  const criterionRatings = [...criterion.ratings]
  if (ratingOrder === 'ascending') {
    criterionRatings.reverse()
  }

  const selectedRatingIndex = criterionRatings.findIndex(
    rating => rating.points === criterionAssessment?.points
  )

  const updateAssessmentData = (params: Partial<UpdateAssessmentData>) => {
    const updatedCriterionAssessment: UpdateAssessmentData = {
      ...criterionAssessment,
      ...params,
      criterionId: criterion.id,
    }
    onUpdateAssessmentData(updatedCriterionAssessment)
  }

  useEffect(() => {
    setCommentText(criterionAssessment?.comments ?? '')
  }, [criterionAssessment, isFreeFormCriterionComments])

  const setPoints = (value: string) => {
    const points = Number(value)

    if (!value.trim().length || Number.isNaN(points)) {
      updateAssessmentData({points: undefined})
      return
    }

    const selectedRating = criterionRatings.find(rating => rating.points === points)

    updateAssessmentData({
      points,
      description: selectedRating?.description,
    })
  }

  const hideComments =
    isFreeFormCriterionComments || (isPreviewMode && !criterionAssessment?.comments?.length)

  return (
    <View as="div" maxWidth="100%">
      <Flex>
        <Flex.Item width="11.25rem" align="start">
          <View
            as="div"
            padding="xxx-small x-small"
            borderWidth="0 small small small"
            height="13.75rem"
            overflowY="auto"
          >
            <View as="div">
              <Text weight="bold">{criterion.description}</Text>
            </View>
            <View as="div" margin="small 0 0 0">
              <Text
                size="small"
                dangerouslySetInnerHTML={htmlEscapeCriteriaLongDescription(criterion)}
              />
            </View>
          </View>
        </Flex.Item>
        {isFreeFormCriterionComments ? (
          <Flex.Item shouldGrow={true} shouldShrink={true} align="start">
            <View height="13.75rem">
              <Grid>
                <Grid.Row colSpacing="none">
                  <Grid.Col>
                    <View
                      as="div"
                      height="13.75rem"
                      padding="x-small small 0 small"
                      borderWidth="0 small small 0"
                      overflowY="auto"
                    >
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
                        <Flex.Item
                          margin={rubricSavedComments.length > 0 ? 'medium 0 0 0' : '0 0 0 0'}
                        >
                          <Text weight="bold">{I18n.t('Comment')}</Text>
                        </Flex.Item>
                        <Flex.Item margin="x-small 0 0 0" shouldGrow={true}>
                          <TextArea
                            label={
                              <ScreenReaderContent>
                                {I18n.t('Criterion Comment')}
                              </ScreenReaderContent>
                            }
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
                    </View>
                  </Grid.Col>
                </Grid.Row>
              </Grid>
            </View>
          </Flex.Item>
        ) : (
          <Flex.Item shouldGrow={true} shouldShrink={true} align="start">
            <View height="13.75rem">
              <Grid>
                <Grid.Row colSpacing="none">
                  {criterionRatings.map((rating, index) => {
                    const highlightedBorder = 'medium'

                    const isHovered = hoveredRatingIndex === index
                    const isSelected = selectedRatingIndex === index

                    const borderWidth =
                      isHovered || isSelected ? highlightedBorder : '0 small small 0'
                    const borderColor = isHovered || isSelected ? 'brand' : 'primary'

                    const onClickRating = (ratingIndex: number) => {
                      if (selectedRatingIndex === ratingIndex) {
                        updateAssessmentData({points: undefined})
                      } else {
                        updateAssessmentData({
                          points: rating.points,
                          description: rating.description,
                        })
                      }
                    }

                    return (
                      // we use the array index because rating may not have an id
                      /* eslint-disable-next-line react/no-array-index-key */
                      <Grid.Col key={`criterion-${criterion.id}-ratings-${index}`}>
                        <View
                          as="button"
                          disabled={isPreviewMode}
                          tabIndex={0}
                          background="transparent"
                          height="13.75rem"
                          width="100%"
                          borderWidth={borderWidth}
                          borderColor={borderColor}
                          overflowY="auto"
                          overflowX="hidden"
                          cursor={isPreviewMode ? 'not-allowed' : 'pointer'}
                          padding="xxx-small x-small 0 x-small"
                          onMouseOver={() => setHoveredRatingIndex(isPreviewMode ? -1 : index)}
                          onMouseOut={() => setHoveredRatingIndex(undefined)}
                          onClick={() => onClickRating(index)}
                          themeOverride={{
                            borderWidthMedium: isSelected ? '0.188rem' : '0.125rem',
                            borderColorBrand: licorice,
                          }}
                          data-testid={`traditional-criterion-${criterion.id}-ratings-${index}`}
                        >
                          <Flex direction="column" height="100%">
                            <Flex.Item>
                              <Text weight="bold">{rating.description}</Text>
                            </Flex.Item>
                            <Flex.Item margin="small 0 0 0" shouldGrow={true} textAlign="start">
                              <View as="div" maxHeight="9.531rem">
                                <Text
                                  size="small"
                                  dangerouslySetInnerHTML={escapeNewLineText(
                                    rating.longDescription
                                  )}
                                />
                              </View>
                            </Flex.Item>
                            <Flex.Item>
                              <View
                                as="div"
                                textAlign="end"
                                position="relative"
                                padding="0 0 x-small 0"
                                overflowX="hidden"
                                overflowY="hidden"
                                minHeight="1.875rem"
                              >
                                <View>
                                  <Text
                                    size="small"
                                    weight="bold"
                                    data-testid={`traditional-criterion-${criterion.id}-ratings-${index}-points`}
                                  >
                                    {!hidePoints && possibleString(rating.points)}
                                  </Text>
                                </View>

                                {isSelected && (
                                  <div
                                    data-testid={`traditional-criterion-${criterion.id}-ratings-${index}-selected`}
                                    style={{
                                      position: 'absolute',
                                      bottom: '0',
                                      height: '0',
                                      width: '0',
                                      left: '50%',
                                      borderLeft: '12px solid transparent',
                                      borderRight: '12px solid transparent',
                                      borderBottom: `12px solid ${licorice}`,
                                      transform: 'translateX(-50%)',
                                    }}
                                  />
                                )}
                              </View>
                            </Flex.Item>
                          </Flex>
                        </View>
                      </Grid.Col>
                    )
                  })}
                </Grid.Row>
              </Grid>
            </View>
          </Flex.Item>
        )}
        {!hidePoints && (
          <Flex.Item width="8.875rem">
            <View
              as="div"
              padding="xxx-small x-small"
              borderWidth="0 small small 0"
              height="13.75rem"
              overflowY="auto"
            >
              <Flex direction="column" height="100%">
                <div style={{display: 'flex', alignItems: 'center'}}>
                  <Flex.Item margin="small 0 0 0">
                    <TextInput
                      renderLabel={
                        <ScreenReaderContent>{I18n.t('Criterion Score')}</ScreenReaderContent>
                      }
                      readOnly={isPreviewMode}
                      data-testid={`comment-score-${criterion.id}`}
                      placeholder="--"
                      width="2.688rem"
                      height="2.375rem"
                      value={criterionAssessment?.points?.toString() || ''}
                      onChange={e => setPoints(e.target.value)}
                      onBlur={e => setPoints(e.target.value)}
                    />
                  </Flex.Item>
                  <Flex.Item margin="small 0 0 x-small">
                    <Text>{'/' + possibleString(criterion.points)}</Text>
                  </Flex.Item>
                </div>
              </Flex>
            </View>
          </Flex.Item>
        )}
      </Flex>
      {!hideComments && (
        <View
          as="div"
          padding="small"
          width="100%"
          borderWidth="0 small small small"
          themeOverride={{paddingMedium: '1.125rem'}}
        >
          <Flex direction="row-reverse">
            {isPreviewMode ? (
              <Flex.Item shouldGrow={true}>
                <CriteriaReadonlyComment commentText={commentText} />
              </Flex.Item>
            ) : (
              <>
                <Flex.Item>
                  <View margin="0 0 0 small" themeOverride={{marginSmall: '1rem'}}>
                    <Button color="secondary" onClick={() => setCommentText('')}>
                      {I18n.t('Clear')}
                    </Button>
                  </View>
                </Flex.Item>
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
              </>
            )}
          </Flex>
        </View>
      )}
    </View>
  )
}
