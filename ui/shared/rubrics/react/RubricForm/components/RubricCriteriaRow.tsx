/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import type {RubricCriterion, RubricRating} from '@canvas/rubrics/react/types/rubric'
import {possibleString, possibleStringRange} from '@canvas/rubrics/react/Points'
import {OutcomeTag, escapeNewLineText, rangingFrom} from '@canvas/rubrics/react/RubricAssessment'
import classnames from 'classnames'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconAiColoredSolid,
  IconDragHandleLine,
  IconDuplicateLine,
  IconEditLine,
  IconOutcomesLine,
  IconTrashLine,
  IconLockLine,
} from '@instructure/ui-icons'
import {Draggable} from 'react-beautiful-dnd'
import '../drag-and-drop/styles.css'

const I18n = createI18nScope('rubrics-criteria-row')

type RubricCriteriaRowProps = {
  criterion: RubricCriterion
  freeFormCriterionComments: boolean
  hidePoints: boolean
  rowIndex: number
  unassessed: boolean
  isGenerated?: boolean
  nextIsGenerated?: boolean
  onDeleteCriterion: () => void
  onDuplicateCriterion: () => void
  onEditCriterion: () => void
}

export const RubricCriteriaRow = ({
  criterion,
  freeFormCriterionComments,
  hidePoints,
  rowIndex,
  unassessed,
  isGenerated,
  nextIsGenerated,
  onDeleteCriterion,
  onDuplicateCriterion,
  onEditCriterion,
}: RubricCriteriaRowProps) => {
  const {
    description,
    longDescription,
    outcome,
    learningOutcomeId,
    points,
    masteryPoints,
    ignoreForScoring,
  } = criterion

  return (
    <Draggable draggableId={criterion.id || Date.now().toString()} index={rowIndex - 1}>
      {(provided, snapshot) => {
        return (
          <div
            ref={provided.innerRef}
            className={classnames('draggable', 'criterion-row', {
              dragging: snapshot.isDragging,
              'generated-criterion-row': isGenerated,
              'divided-criterion-row': !isGenerated && !nextIsGenerated,
            })}
            {...provided.draggableProps}
          >
            <Flex data-testid="rubric-criteria-row">
              <Flex.Item align="start">
                <div className="drag-handle" {...provided.dragHandleProps}>
                  <IconDragHandleLine />
                </div>
              </Flex.Item>
              <Flex.Item align="start">
                <View as="div" margin="xxx-small 0 0 medium">
                  <Text weight="bold" data-testid="rubric-criteria-row-index">
                    {rowIndex}.
                  </Text>
                </View>
              </Flex.Item>
              <Flex.Item margin="0 x-small" align="start" shouldGrow={true} shouldShrink={true}>
                {learningOutcomeId ? (
                  <>
                    <View as="div">
                      <OutcomeTag displayName={criterion.description} />
                      <Tooltip
                        renderTip={I18n.t("An outcome can't be edited")}
                        data-testid={`outcome-tooltip-${criterion.id}`}
                      >
                        <IconLockLine
                          style={{marginLeft: 12}}
                          data-testid={`outcome-lock-icon-${criterion.id}`}
                        />
                      </Tooltip>
                    </View>
                    {outcome?.displayName && (
                      <View
                        as="div"
                        margin="small 0 0 0"
                        data-testid="rubric-criteria-outcome-subtitle"
                      >
                        <Text weight="bold">{outcome?.displayName}</Text>
                      </View>
                    )}
                    <View
                      as="div"
                      margin="small 0 0 0"
                      data-testid="rubric-criteria-row-description"
                    >
                      {/* html sanitized by server */}
                      <Text dangerouslySetInnerHTML={{__html: longDescription ?? ''}} />
                    </View>
                    {!hidePoints && (
                      <View
                        as="div"
                        margin="small 0 0 0"
                        data-testid="rubric-criteria-row-threshold"
                      >
                        <Text>
                          {I18n.t('Threshold: %{threshold}', {
                            threshold: possibleString(masteryPoints),
                          })}
                        </Text>
                      </View>
                    )}
                  </>
                ) : (
                  <>
                    <View
                      as="div"
                      margin="xxx-small 0 0 0"
                      data-testid="rubric-criteria-row-description"
                    >
                      <Flex alignItems="center" gap="x-small">
                        {isGenerated && (
                          <span data-testid="rubric-criteria-row-ai-icon">
                            <IconAiColoredSolid />
                          </span>
                        )}
                        <Text weight="bold">{description}</Text>
                      </Flex>
                    </View>
                    <View as="div" data-testid="rubric-criteria-row-long-description">
                      <Text>{longDescription}</Text>
                    </View>
                  </>
                )}
                {freeFormCriterionComments && (
                  <View
                    as="div"
                    margin="small 0 0 0"
                    data-testid="rubric-criteria-row-freeform-comment"
                  >
                    <Text>
                      {I18n.t(
                        'This area will be used by the assessor to leave comments related to this criterion.',
                      )}
                    </Text>
                  </View>
                )}
              </Flex.Item>
              <Flex.Item align="start">
                {!ignoreForScoring && !hidePoints && (
                  <Pill
                    color="info"
                    disabled={true}
                    themeOverride={{
                      background: 'rgb(3, 116, 181)',
                      infoColor: 'white',
                    }}
                  >
                    <Text data-testid="rubric-criteria-row-points" size="x-small">
                      {possibleString(points)}
                    </Text>
                  </Pill>
                )}
                <View as="span" margin="0 0 0 medium">
                  <IconButton
                    withBackground={false}
                    withBorder={false}
                    screenReaderLabel={
                      learningOutcomeId
                        ? I18n.t('View Outcome Criterion')
                        : I18n.t('Edit Criterion')
                    }
                    onClick={onEditCriterion}
                    size="small"
                    themeOverride={{smallHeight: '18px'}}
                    data-testid="rubric-criteria-row-edit-button"
                  >
                    {learningOutcomeId ? <IconOutcomesLine /> : <IconEditLine />}
                  </IconButton>
                </View>

                {unassessed && (
                  <View as="span" margin="0 0 0 medium">
                    <IconButton
                      withBackground={false}
                      withBorder={false}
                      screenReaderLabel={I18n.t('Delete Criterion')}
                      onClick={onDeleteCriterion}
                      size="small"
                      themeOverride={{smallHeight: '18px'}}
                      data-testid="rubric-criteria-row-delete-button"
                    >
                      <IconTrashLine />
                    </IconButton>
                  </View>
                )}

                {unassessed && (
                  <View as="span" margin="0 0 0 medium">
                    <IconButton
                      withBackground={false}
                      withBorder={false}
                      screenReaderLabel={I18n.t('Duplicate Criterion')}
                      onClick={onDuplicateCriterion}
                      size="small"
                      themeOverride={{smallHeight: '18px'}}
                      data-testid="rubric-criteria-row-duplicate-button"
                    >
                      <IconDuplicateLine />
                    </IconButton>
                  </View>
                )}
              </Flex.Item>
            </Flex>
            {!freeFormCriterionComments && (
              <RatingScaleAccordion
                hidePoints={hidePoints}
                ratings={criterion.ratings}
                criterionUseRange={criterion.criterionUseRange}
                isGenerated={isGenerated}
              />
            )}
          </div>
        )
      }}
    </Draggable>
  )
}

type RatingScaleAccordionProps = {
  hidePoints: boolean
  ratings: RubricRating[]
  criterionUseRange: boolean
  isGenerated?: boolean
}
const RatingScaleAccordion = ({
  hidePoints,
  ratings,
  criterionUseRange,
  isGenerated = false,
}: RatingScaleAccordionProps) => {
  return (
    <View as="div" padding="small 0 0 xx-large">
      <ToggleDetails
        data-testid="criterion-row-rating-accordion"
        defaultExpanded={isGenerated}
        summary={`${I18n.t('Rating Scale: %{ratingsLength}', {ratingsLength: ratings.length})}`}
      >
        {ratings.map((rating, index) => {
          const scale = ratings.length - (index + 1)
          const spacing = index === 0 ? 'medium' : 'large'
          const min = criterionUseRange ? rangingFrom(ratings, index) : undefined
          return (
            <RatingScaleAccordionItem
              hidePoints={hidePoints}
              rating={rating}
              key={`rating-scale-item-${rating.id}-${index}`}
              scale={scale}
              spacing={spacing}
              min={min}
            />
          )
        })}
      </ToggleDetails>
    </View>
  )
}

type RatingScaleAccordionItemProps = {
  hidePoints: boolean
  rating: RubricRating
  scale: number
  spacing: string
  min?: number
}
const RatingScaleAccordionItem = ({
  hidePoints,
  rating,
  scale,
  spacing,
  min,
}: RatingScaleAccordionItemProps) => {
  return (
    <View as="div" margin={`${spacing} 0 0 xx-small`} data-testid="rating-scale-accordion-item">
      <Flex>
        <Flex.Item align="start">
          <View as="div" width="2.25rem" margin="0 0 0 xx-small">
            <Text width="0.75rem">{scale}</Text>
          </View>
        </Flex.Item>
        <Flex.Item align="start">
          <View as="div" width="7.063rem">
            <View as="div" maxWidth="5.563rem">
              <Text>{rating.description}</Text>
            </View>
          </View>
        </Flex.Item>
        <Flex.Item shouldShrink={true} shouldGrow={true} align="start">
          <View as="div">
            <Text
              dangerouslySetInnerHTML={escapeNewLineText(rating.longDescription)}
              themeOverride={{paragraphMargin: 0}}
            />
          </View>
        </Flex.Item>
        <Flex.Item align="start">
          <View as="div" margin="0 0 0 medium">
            {!hidePoints && (
              <Text>
                {min != null
                  ? possibleStringRange(min, rating.points)
                  : possibleString(rating.points)}
              </Text>
            )}
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}
