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

import {useEffect, useState} from 'react'
import {FormMessage} from '@instructure/ui-form-field'
import {RubricRating} from '../../../types/rubric'
import {RubricRatingFieldSetting} from '../../types/RubricForm'
import {RatingRowFullWidth} from './RatingRowFullWidth'
import {RatingRowCompact} from './RatingRowCompact'

type RatingRowProps = {
  checkValidation: boolean
  criterionUseRange: boolean
  hidePoints: boolean
  index: number
  isFullWidth: boolean
  isLastIndex: boolean
  rangeStart?: number
  rating: RubricRating
  ratingInputRefs: React.MutableRefObject<HTMLInputElement[]>
  scale: number
  showRemoveButton: boolean
  onChange: (rating: RubricRating) => void
  onRemove: () => void
  onPointsBlur: () => void
  handleMoveRating: (index: number, moveValue: number) => void
}
export const RatingRow = ({
  checkValidation,
  criterionUseRange,
  rangeStart,
  hidePoints,
  index,
  isFullWidth,
  isLastIndex,
  rating,
  ratingInputRefs,
  scale,
  showRemoveButton,
  onChange,
  onRemove,
  onPointsBlur,
  handleMoveRating,
}: RatingRowProps) => {
  const [pointsInputText, setPointsInputText] = useState<string | number>(0)

  useEffect(() => {
    setPointsInputText(rating.points)
  }, [rating.points])

  const setRatingForm: RubricRatingFieldSetting = (key, value) => {
    onChange({...rating, [key]: value})
  }

  const errorMessage: FormMessage[] =
    !rating.description.trim().length && checkValidation
      ? [{text: 'Rating Name Required', type: 'error'}]
      : []

  const ratingRowProps = {
    criterionUseRange,
    errorMessage,
    hidePoints,
    index,
    rating,
    ratingInputRefs,
    scale,
    showRemoveButton,
    onPointsBlur,
    setRatingForm,
    setPointsInputText,
    rangeStart: rangeStart ?? 0,
    pointsInputText,
    onRemove,
  }

  return isFullWidth ? (
    <RatingRowFullWidth {...ratingRowProps} />
  ) : (
    <RatingRowCompact
      {...ratingRowProps}
      isLastIndex={isLastIndex}
      handleMoveRating={handleMoveRating}
    />
  )
}
