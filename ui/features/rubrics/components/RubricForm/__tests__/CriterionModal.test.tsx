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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import {CriterionModal, DEFAULT_RUBRIC_RATINGS} from '../CriterionModal'

describe('CriterionModal tests', () => {
  const renderComponent = () => {
    return render(<CriterionModal isOpen={true} onDismiss={() => {}} />)
  }

  describe('Ratings Tests', () => {
    it('should render the default ratings', () => {
      const {queryAllByTestId} = renderComponent()

      for (let i = 0; i < DEFAULT_RUBRIC_RATINGS.length; i++) {
        const ratingName = queryAllByTestId(`rating-name`)[i] as HTMLInputElement
        const ratingPoints = queryAllByTestId(`rating-points`)[i] as HTMLInputElement
        const ratingScale = queryAllByTestId(`rating-scale`)[i] as HTMLInputElement
        const expectedRatingScale = DEFAULT_RUBRIC_RATINGS.length - (i + 1)
        expect(ratingPoints.value).toEqual(DEFAULT_RUBRIC_RATINGS[i].points.toString())
        expect(ratingName.value).toEqual(DEFAULT_RUBRIC_RATINGS[i].description.toString())
        expect(ratingScale.value).toEqual(expectedRatingScale.toString())
      }
    })

    it('should add a new rating at specified index', () => {
      const {queryAllByTestId} = renderComponent()
      const addRatingRow = queryAllByTestId('add-rating-row')[1]

      fireEvent.mouseOver(addRatingRow)
      fireEvent.click(addRatingRow.firstChild as Element)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames.length).toEqual(DEFAULT_RUBRIC_RATINGS.length + 1)

      const ratingName = totalRatingNames[1] as HTMLInputElement
      const ratingPoints = queryAllByTestId(`rating-points`)[1] as HTMLInputElement
      const ratingScale = queryAllByTestId(`rating-scale`)[1] as HTMLInputElement
      expect(ratingPoints.value).toEqual('0')
      expect(ratingName.value).toEqual('')
      expect(ratingScale.value).toEqual((DEFAULT_RUBRIC_RATINGS.length - 1).toString())
    })

    it('should add a new rating to the end of the list', () => {
      const {queryAllByTestId} = renderComponent()
      const addRatingRow = queryAllByTestId('add-rating-row')[DEFAULT_RUBRIC_RATINGS.length]

      fireEvent.mouseOver(addRatingRow)
      fireEvent.click(addRatingRow.firstChild as Element)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames.length).toEqual(DEFAULT_RUBRIC_RATINGS.length + 1)

      const newLastIndex = totalRatingNames.length - 1
      const ratingName = totalRatingNames[newLastIndex] as HTMLInputElement
      const ratingPoints = queryAllByTestId(`rating-points`)[newLastIndex] as HTMLInputElement
      const ratingScale = queryAllByTestId(`rating-scale`)[newLastIndex] as HTMLInputElement
      expect(ratingPoints.value).toEqual('0')
      expect(ratingName.value).toEqual('')
      expect(ratingScale.value).toEqual('0')
    })

    it('should remove a rating at specified index', () => {
      const {queryAllByTestId} = renderComponent()
      const removeRating = queryAllByTestId('remove-rating')[2]

      fireEvent.click(removeRating)

      const totalRatingNames = queryAllByTestId('rating-name')
      expect(totalRatingNames.length).toEqual(DEFAULT_RUBRIC_RATINGS.length - 1)

      const removedRating = totalRatingNames.find(
        ratingName =>
          (ratingName as HTMLInputElement).value === DEFAULT_RUBRIC_RATINGS[2].description
      )
      expect(removedRating).toBeUndefined()
    })
  })
})
