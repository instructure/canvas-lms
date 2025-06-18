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

import {FC} from 'react'
import {colors} from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {possibleString, possibleStringRange} from '../Points'
import type {RubricCriterion, RubricRating} from '../types/rubric'
import {escapeNewLineText, rubricSelectedAriaLabel} from './utils/rubricUtils'

type TraditionalViewCriterionRatingProps = {
  criterionId: RubricCriterion['id']
  hidePoints: boolean
  index: number
  isHovered: boolean
  isLastRating: boolean
  isPreviewMode: boolean
  isSelected: boolean
  isSelfAssessmentSelected: boolean
  min?: number
  rating: RubricRating
  ratingCellMinWidth: string
  elementRef: (element: Element | null) => void
  onClickRating: (ratingId: string) => void
  setHoveredRatingIndex: (index: number | undefined) => void
}

export const TraditionalViewCriterionRating: FC<TraditionalViewCriterionRatingProps> = ({
  criterionId,
  hidePoints,
  index,
  isHovered,
  isLastRating,
  isPreviewMode,
  isSelected,
  isSelfAssessmentSelected,
  min,
  rating,
  ratingCellMinWidth,
  elementRef,
  onClickRating,
  setHoveredRatingIndex,
}) => {
  const borderColor = isHovered || isSelected ? 'brand' : 'primary'
  const primaryBorderColor = `${colors.contrasts.grey1214} ${
    isLastRating ? colors.contrasts.grey1214 : colors.primitives.grey14
  } ${colors.contrasts.grey1214} ${colors.contrasts.grey1214}`

  const selectedText = rubricSelectedAriaLabel(isSelected, isSelfAssessmentSelected)

  return (
    <Flex.Item as="div" shouldGrow shouldShrink>
      <View
        as="div"
        borderColor={borderColor}
        borderWidth={`0 ${isLastRating ? '0' : 'small'} 0 0`}
        height="100%"
        width="100%"
        padding="0"
        margin="0"
        minWidth={ratingCellMinWidth}
        themeOverride={{
          borderColorBrand: colors.contrasts.green4570,
          borderColorPrimary: primaryBorderColor,
        }}
        elementRef={elementRef}
        style={{flex: '1'}}
      >
        <View
          as="button"
          disabled={isPreviewMode}
          tabIndex={0}
          background="transparent"
          height="100%"
          width="100%"
          borderWidth="small"
          borderColor={borderColor}
          overflowX="visible"
          overflowY="visible"
          cursor={isPreviewMode ? 'not-allowed' : 'pointer'}
          padding="x-small small 0 small"
          position="relative"
          onMouseOver={() => setHoveredRatingIndex(isPreviewMode ? -1 : index)}
          onMouseOut={() => setHoveredRatingIndex(undefined)}
          onClick={() => onClickRating(rating.id)}
          themeOverride={{
            borderWidthSmall: '0.125rem',
            borderColorBrand: colors.contrasts.green4570,
            borderColorPrimary: 'transparent',
          }}
          data-testid={`traditional-criterion-${criterionId}-ratings-${index}`}
        >
          <ScreenReaderContent>{selectedText}</ScreenReaderContent>

          {isSelfAssessmentSelected && (
            <div
              style={{
                position: 'absolute',
                inset: '2px',
                backgroundColor: 'transparent',
                color: colors.contrasts.green4570,
                border: '2px dashed #03893D',
                borderRadius: '4px',
                pointerEvents: 'none',
              }}
            />
          )}
          <Flex direction="column" height="100%" alignItems="stretch">
            <Flex.Item>
              <Text weight="bold">{rating.description}</Text>
            </Flex.Item>
            <Flex.Item margin="small 0 0 0" textAlign="start" shouldGrow shouldShrink>
              <View as="div">
                <Text
                  size="small"
                  dangerouslySetInnerHTML={escapeNewLineText(rating.longDescription)}
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
                    data-testid={`traditional-criterion-${criterionId}-ratings-${index}-points`}
                  >
                    {!hidePoints &&
                      (min != null
                        ? possibleStringRange(min, rating.points)
                        : possibleString(rating.points))}
                  </Text>
                </View>

                {isSelected && (
                  <div
                    data-testid={`traditional-criterion-${criterionId}-ratings-${index}-selected`}
                    style={{
                      position: 'absolute',
                      bottom: '0',
                      height: '0',
                      width: '0',
                      left: '50%',
                      borderLeft: '12px solid transparent',
                      borderRight: '12px solid transparent',
                      borderBottom: `12px solid ${colors.contrasts.green4570}`,
                      transform: 'translateX(-50%)',
                    }}
                  />
                )}
              </View>
            </Flex.Item>
          </Flex>
        </View>
      </View>
    </Flex.Item>
  )
}
