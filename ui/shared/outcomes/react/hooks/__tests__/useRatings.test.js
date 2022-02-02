/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {renderHook} from '@testing-library/react-hooks/dom'
import useRatings, {defaultOutcomesManagementRatings} from '../useRatings'

const expectDescriptions = (result, expectedDescriptions) => {
  expect(result.current.ratings.map(r => r.description)).toStrictEqual(expectedDescriptions)
}

const expectDescriptionErrors = (result, expectedDescriptionsErrors) => {
  expect(result.current.ratings.map(r => r.descriptionError)).toStrictEqual(
    expectedDescriptionsErrors
  )
}

const expectPoints = (result, expectedPoints) => {
  expect(result.current.ratings.map(r => r.points)).toStrictEqual(expectedPoints)
}

const expectPointsErrors = (result, expectedPointsErrors) => {
  expect(result.current.ratings.map(r => r.pointsError)).toStrictEqual(expectedPointsErrors)
}

const changeRating = (result, ratingIndex, attrs) => {
  const newRatings = [...result.current.ratings]
  const rating = newRatings[ratingIndex]
  newRatings.splice(ratingIndex, 1, {
    ...rating,
    ...attrs
  })
  result.current.setRatings(newRatings)
}

describe('useRatings', () => {
  const initialRatings = defaultOutcomesManagementRatings

  test('should create custom hook with initialRatings', () => {
    const {result} = renderHook(() => useRatings({initialRatings}))
    expectDescriptions(result, [
      'Exceeds Mastery',
      'Mastery',
      'Near Mastery',
      'Below Mastery',
      'Well Below Mastery'
    ])
    expectPoints(result, [4, 3, 2, 1, 0])
  })

  describe('Updating', () => {
    it('should reflect changes in ratings', () => {
      const {result} = renderHook(() => useRatings({initialRatings}))

      changeRating(result, 0, {description: 'New Exceeds Mastery', points: 5})
      changeRating(result, 1, {description: 'New Mastery', points: 4})

      expectDescriptions(result, [
        'New Exceeds Mastery',
        'New Mastery',
        'Near Mastery',
        'Below Mastery',
        'Well Below Mastery'
      ])

      expectPoints(result, [5, 4, 2, 1, 0])
    })

    it('returns false for hasChanged if ratings have not changed', () => {
      const {result} = renderHook(() => useRatings({initialRatings}))
      expect(result.current.hasChanged).toBe(false)
    })

    it('returns true for hasChanged if ratings have changed', () => {
      const {result} = renderHook(() => useRatings({initialRatings}))
      changeRating(result, 0, {description: 'New Exceeds Mastery', points: 5})
      changeRating(result, 1, {description: 'New Mastery', points: 4})
      expect(result.current.hasChanged).toBe(true)
    })
  })

  describe('Validations', () => {
    describe('Description validations', () => {
      it('should be ok when receiving good data', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {description: 'Any description'})

        expectDescriptionErrors(result, [null, null, null, null, null])
        expect(result.current.hasError).toBeFalsy()
      })

      it('should validate blank', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {description: ''})

        expectDescriptionErrors(result, ['Missing required description', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })
    })

    describe('Points validations', () => {
      it('should be ok for positive integer', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {points: '10'})

        expectPointsErrors(result, [null, null, null, null, null])
        expect(result.current.hasError).toBeFalsy()
      })

      it('should be ok for positive float', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {points: '10.5'})

        expectPointsErrors(result, [null, null, null, null, null])
        expect(result.current.hasError).toBeFalsy()
      })

      it('should validate blank points', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {points: ''})

        expectPointsErrors(result, ['Missing required points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate invalid points', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {points: 'lorem'})

        expectPointsErrors(result, ['Invalid points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate points with comma as invalid points', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {points: '0,5'})

        expectPointsErrors(result, ['Invalid points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate negative points', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        changeRating(result, 0, {points: '-1'})

        expectPointsErrors(result, ['Negative points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate unique points', () => {
        const {result} = renderHook(() => useRatings({initialRatings}))

        // change the first points to match the second
        changeRating(result, 0, {points: '3'})

        // note, the invalid message should be on the second
        expectPointsErrors(result, [null, 'Points must be unique', null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })
    })
  })
})
