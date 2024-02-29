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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {RubricCriterion, RubricRating} from '@canvas/rubrics/react/types/rubric'
import {possibleString} from '@canvas/rubrics/react/Points'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconArrowOpenDownLine,
  IconArrowOpenEndLine,
  IconDragHandleLine,
  IconDuplicateLine,
  IconEditLine,
  IconTrashLine,
} from '@instructure/ui-icons'

const I18n = useI18nScope('rubrics-criteria-row')

type RubricCriteriaRowProps = {
  criterion: RubricCriterion
  rowIndex: number
  unassessed: boolean
  onDeleteCriterion: () => void
  onDuplicateCriterion: () => void
  onEditCriterion: () => void
}

export const RubricCriteriaRow = ({
  criterion,
  rowIndex,
  unassessed,
  onDeleteCriterion,
  onDuplicateCriterion,
  onEditCriterion,
}: RubricCriteriaRowProps) => {
  const {description, longDescription, points} = criterion

  return (
    <>
      <Flex data-testid="rubric-criteria-row">
        <Flex.Item align="start" draggable={unassessed}>
          <View as="div" cursor="pointer">
            <IconDragHandleLine />
          </View>
        </Flex.Item>
        <Flex.Item align="start" shouldShrink={true}>
          <View as="div" margin="xxx-small 0 0 small" themeOverride={{marginSmall: '1.5rem'}}>
            <Text weight="bold" data-testid="rubric-criteria-row-index">
              {rowIndex}.
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item margin="0 small" align="start" shouldGrow={true} shouldShrink={true}>
          <View as="div">
            <Tag
              text={
                <AccessibleContent alt="Remove outcome">
                  <Text>FA.V.CR.1</Text>
                </AccessibleContent>
              }
              size="small"
              dismissible={true}
              onClick={() => {}}
              themeOverride={{
                defaultBackground: 'white',
                defaultBorderColor: 'rgb(3, 116, 181)',
                defaultColor: 'rgb(3, 116, 181)',
              }}
            />
          </View>
          <View as="div" margin="small 0 0 0" data-testid="rubric-criteria-row-description">
            <Text weight="bold">{description}</Text>
          </View>
          <View as="div" data-testid="rubric-criteria-row-long-description">
            <Text>{longDescription}</Text>
          </View>
        </Flex.Item>
        <Flex.Item align="start">
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
          <View as="span" margin="0 0 0 medium">
            <IconButton
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t('Edit Criterion')}
              onClick={onEditCriterion}
              size="small"
              themeOverride={{smallHeight: '18px'}}
              data-testid="rubric-criteria-row-edit-button"
            >
              <IconEditLine />
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
      <RatingScaleAccordion ratings={criterion.ratings} />

      <View as="hr" margin="medium 0 medium 0" />
    </>
  )
}

type RatingScaleAccordionProps = {
  ratings: RubricRating[]
}
const RatingScaleAccordion = ({ratings}: RatingScaleAccordionProps) => {
  const [ratingsOpen, setRatingsOpen] = useState(false)

  return (
    <View
      as="div"
      padding="medium 0 0 large"
      themeOverride={{paddingMedium: '1.5rem', paddingLarge: '3.35rem'}}
    >
      <View
        as="button"
        cursor="pointer"
        onClick={() => setRatingsOpen(!ratingsOpen)}
        background="transparent"
        display="block"
        borderWidth="none"
        textAlign="start"
        type="button"
        position="relative"
      >
        {ratingsOpen ? (
          <IconArrowOpenDownLine width="18" height="18" />
        ) : (
          <IconArrowOpenEndLine width="18" height="18" />
        )}

        <View as="span" margin="0 0 0 small" data-testid="criterion-row-rating-accordion">
          <Text>
            {I18n.t('Rating Scale')}: {ratings.length}
          </Text>
        </View>
      </View>

      {ratingsOpen &&
        ratings.map((rating, index) => {
          const scale = ratings.length - (index + 1)
          const spacing = index === 0 ? '1.5rem' : '2.25rem'
          return (
            <RatingScaleAccordionItem
              rating={rating}
              // eslint-disable-next-line react/no-array-index-key
              key={`rating-scale-item-${rating.id}-${index}`}
              scale={scale}
              spacing={spacing}
            />
          )
        })}
    </View>
  )
}

type RatingScaleAccordionItemProps = {
  rating: RubricRating
  scale: number
  spacing: string
}
const RatingScaleAccordionItem = ({rating, scale, spacing}: RatingScaleAccordionItemProps) => {
  return (
    <View
      as="div"
      margin="small 0 0 xx-small"
      themeOverride={{marginSmall: spacing}}
      data-testid="rating-scale-accordion-item"
    >
      <Flex>
        <Flex.Item align="start">
          <View
            as="div"
            width="2.25rem"
            margin="0 0 0 small"
            themeOverride={{marginSmall: '0.25rem'}}
          >
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
            <Text>{rating.longDescription}</Text>
          </View>
        </Flex.Item>
        <Flex.Item align="start">
          <View as="div" margin="0 0 0 medium" themeOverride={{marginMedium: '1.5rem'}}>
            <Text>{possibleString(rating.points)}</Text>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}
