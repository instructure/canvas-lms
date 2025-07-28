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

import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {RubricRating} from '../../../types/rubric'
import {MutableRefObject} from 'react'

const I18n = createI18nScope('rubrics-criterion-modal')

type RatingPointsInputProps = {
  index: number
  isRange: boolean
  pointsInputText: string | number
  rating: RubricRating
  onPointsBlur: () => void
  setNewRating: (newNumber: number, textValue: string) => void
  shouldRenderLabel: boolean
  ratingInputRefs?: MutableRefObject<HTMLInputElement[]>
}
export const RatingPointsInput = ({
  index,
  isRange,
  pointsInputText,
  rating,
  onPointsBlur,
  setNewRating,
  shouldRenderLabel,
  ratingInputRefs,
}: RatingPointsInputProps) => {
  const setNumber = (value: number) => {
    if (Number.isNaN(value)) return 0

    return value < 0 ? 0 : value
  }

  const labelText = isRange ? I18n.t('Point Range') : I18n.t('Points')
  const renderLabel = shouldRenderLabel ? (
    labelText
  ) : (
    <ScreenReaderContent>{labelText}</ScreenReaderContent>
  )
  return (
    <NumberInput
      inputRef={el => {
        if (ratingInputRefs && ratingInputRefs.current && el) {
          ratingInputRefs.current[index] = el
        }
      }}
      allowStringValue={true}
      renderLabel={renderLabel}
      value={pointsInputText}
      onIncrement={() => {
        const newNumber = setNumber(Math.floor(rating.points) + 1)
        setNewRating(newNumber, newNumber.toString())
      }}
      onDecrement={() => {
        const newNumber = setNumber(Math.floor(rating.points) - 1)
        setNewRating(newNumber, newNumber.toString())
      }}
      onChange={(_e, value) => {
        if (!/^\d*[.,]?\d{0,2}$/.test(value)) return

        const newNumber = setNumber(Number(value.replace(',', '.')))
        setNewRating(newNumber, value)
      }}
      data-testid="rating-points"
      width="6.25rem"
      display={isRange ? 'inline-block' : 'block'}
      onBlur={() => {
        onPointsBlur()
      }}
    />
  )
}
