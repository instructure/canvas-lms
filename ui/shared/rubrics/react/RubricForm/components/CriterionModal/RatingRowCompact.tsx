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

import {Flex} from '@instructure/ui-flex'

import {RatingDescription} from './RatingDescription'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {RatingPointsInput} from './RatingPointsInput'
import {RatingRowProps} from '../../types/RubricForm'
import {RatingLongDescription} from './RatingLongDescription'
import {CompactRatingPopover} from './CompactRatingPopover'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('rubrics-criterion-modal')

type RatingRowCompactProps = RatingRowProps & {
  isLastIndex: boolean
  handleMoveRating: (index: number, moveValue: number) => void
}

export const RatingRowCompact = ({
  criterionUseRange,
  errorMessage,
  hidePoints,
  index,
  rating,
  scale,
  rangeStart,
  ratingInputRefs,
  pointsInputText,
  onPointsBlur,
  setRatingForm,
  setPointsInputText,
  showRemoveButton,
  onRemove,
  isLastIndex,
  handleMoveRating,
}: RatingRowCompactProps) => {
  return (
    <View as="div" margin="small 0">
      <Flex wrap="wrap" gap="small">
        <Flex.Item size={criterionUseRange ? '2.75rem' : '4.688rem'} shouldGrow={hidePoints}>
          <TextInput
            data-testid="rating-scale"
            disabled
            renderLabel={I18n.t('Display')}
            value={scale.toString()}
            width="2.375rem"
            onChange={() => {}}
          />
        </Flex.Item>
        {!hidePoints && (
          <Flex.Item shouldGrow shouldShrink>
            <View as="div" display="inline-block">
              {criterionUseRange && (
                <View
                  as="span"
                  data-testid="range-start"
                  display="inline-block"
                  margin="medium small 0"
                  themeOverride={{marginMedium: '2rem'}}
                >
                  {rangeStart ? I18n.t('%{rangeStart} to ', {rangeStart}) : `--`}
                </View>
              )}
              <RatingPointsInput
                index={index}
                isRange={criterionUseRange}
                pointsInputText={pointsInputText}
                rating={rating}
                ratingInputRefs={ratingInputRefs}
                onPointsBlur={onPointsBlur}
                setNewRating={(newNumber, textValue) => {
                  setRatingForm('points', newNumber)
                  setPointsInputText(textValue)
                }}
                shouldRenderLabel={true}
              />
            </View>
          </Flex.Item>
        )}
        <Flex.Item align="end">
          <CompactRatingPopover
            isFirstIndex={index === 0}
            isLastIndex={isLastIndex}
            onMoveUp={() => handleMoveRating(index, -1)}
            onMoveDown={() => handleMoveRating(index, 1)}
            onDelete={onRemove}
            showRemoveButton={showRemoveButton}
          />
        </Flex.Item>
      </Flex>
      <View as="div" margin="medium 0 small">
        <RatingDescription
          description={rating.description}
          errorMessage={errorMessage}
          setRatingForm={setRatingForm}
          shouldRenderLabel={true}
        />
      </View>
      <View as="div" margin="medium 0 small">
        <RatingLongDescription
          limitHeight={false}
          longDescription={rating.longDescription}
          setRatingForm={setRatingForm}
          shouldRenderLabel={true}
        />
      </View>
      <View as="hr" />
    </View>
  )
}
