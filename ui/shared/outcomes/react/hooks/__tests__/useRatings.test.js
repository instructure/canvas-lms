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
import useRatings, {defaultRatings, defaultMasteryPoints, prepareRatings} from '../useRatings'

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
    ...attrs,
  })
  result.current.setRatings(newRatings)
}

const changeMasteryPoints = (result, points) => result.current.setMasteryPoints(points)

const expectMasteryPoints = (result, expectedMasteryPoints) => {
  expect(result.current.masteryPoints.value).toEqual(expectedMasteryPoints)
}

const expectMasteryPointsErrors = (result, expectedMasteryPointsError) => {
  expect(result.current.masteryPoints.error).toEqual(expectedMasteryPointsError)
}

describe('useRatings', () => {
  const initialRatings = defaultRatings
  const initialMasteryPoints = defaultMasteryPoints

  test('should create custom hook with initialRatings', () => {
    const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))
    expectDescriptions(result, [
      'Exceeds Mastery',
      'Mastery',
      'Near Mastery',
      'Below Mastery',
      'No Evidence',
    ])
    expectPoints(result, [4, 3, 2, 1, 0])
    expect(result.current.masteryPoints.value).toEqual(initialMasteryPoints)
  })

  describe('Updating', () => {
    it('should reflect changes in ratings', () => {
      const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

      changeRating(result, 0, {description: 'New Exceeds Mastery', points: 5}, false)
      changeRating(result, 1, {description: 'New Mastery', points: 4}, true)

      expectDescriptions(result, [
        'New Exceeds Mastery',
        'New Mastery',
        'Near Mastery',
        'Below Mastery',
        'No Evidence',
      ])

      expectPoints(result, [5, 4, 2, 1, 0])
    })

    it('should reflect changes in mastery points', () => {
      const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

      changeMasteryPoints(result, 11)

      expectMasteryPoints(result, 11)
    })

    it('returns false for hasChanged if neither ratings nor mastery points have changed', () => {
      const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))
      expect(result.current.hasChanged).toBe(false)
    })

    it('returns true for hasChanged if ratings have changed', () => {
      const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))
      changeRating(result, 0, {description: 'New Exceeds Mastery', points: 5}, false)
      changeRating(result, 1, {description: 'New Mastery', points: 4}, true)
      expect(result.current.hasChanged).toBe(true)
    })

    it('returns true for hasChanged if mastery points have changed', () => {
      const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

      changeMasteryPoints(result, 11)

      expect(result.current.hasChanged).toBe(true)
    })
  })

  describe('Validations', () => {
    describe('Description validations', () => {
      it('should be ok when receiving good data', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {description: 'Any description'}, false)

        expectDescriptionErrors(result, [null, null, null, null, null])
        expect(result.current.hasError).toBeFalsy()
      })

      it('should validate blank', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {description: ''}, false)

        expectDescriptionErrors(result, ['Missing required description', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })
    })

    describe('Points validations', () => {
      it('should be ok for positive integer', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {points: '10'}, false)

        expectPointsErrors(result, [null, null, null, null, null])
        expect(result.current.hasError).toBeFalsy()
      })

      it('should be ok for positive float', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {points: '10.5'}, false)

        expectPointsErrors(result, [null, null, null, null, null])
        expect(result.current.hasError).toBeFalsy()
      })

      it('should validate blank points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {points: ''}, false)

        expectPointsErrors(result, ['Missing required points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate invalid points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {points: 'lorem'}, false)

        expectPointsErrors(result, ['Invalid points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate points with comma as invalid points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {points: '0,5'}, false)

        expectPointsErrors(result, ['Invalid points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate negative points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeRating(result, 0, {points: '-1'}, false)

        expectPointsErrors(result, ['Negative points', null, null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })

      it('should validate unique points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        // change the first points to match the second
        changeRating(result, 0, {points: '3'}, false)

        // note, the invalid message should be on the second
        expectPointsErrors(result, [null, 'Points must be unique', null, null, null])
        expect(result.current.hasError).toBeTruthy()
      })
    })

    describe('Mastery points validations', () => {
      it('should pass validations for positive integer', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeMasteryPoints(result, 3)

        expectMasteryPointsErrors(result, null)
        expect(result.current.hasError).toBeFalsy()
      })

      it('should pass validations for positive float', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeMasteryPoints(result, 3.5)

        expectMasteryPointsErrors(result, null)
        expect(result.current.hasError).toBeFalsy()
      })

      it('should generate error if no points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeMasteryPoints(result, '')

        expectMasteryPointsErrors(result, 'Missing required points')
        expect(result.current.hasError).toBeTruthy()
      })

      it('should generate error if invalid points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeMasteryPoints(result, 'lorem')

        expectMasteryPointsErrors(result, 'Invalid points')
        expect(result.current.hasError).toBeTruthy()
      })

      it('should generate error if points have comma delimiter', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeMasteryPoints(result, '0,5')

        expectMasteryPointsErrors(result, 'Invalid points')
        expect(result.current.hasError).toBeTruthy()
      })

      it('should generate error if negative points', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeMasteryPoints(result, '-1')

        expectMasteryPointsErrors(result, 'Negative points')
        expect(result.current.hasError).toBeTruthy()
      })

      it('should generate error if mastery points greater than max rating', () => {
        const {result} = renderHook(() => useRatings({initialRatings, initialMasteryPoints}))

        changeMasteryPoints(result, 11)

        expectMasteryPointsErrors(result, 'Above max rating')
        expect(result.current.hasError).toBeTruthy()
      })

      it('should generate error if mastery points less than min rating', () => {
        const {result} = renderHook(() =>
          useRatings({
            initialRatings: defaultRatings.filter(r => r.points !== 0),
            initialMasteryPoints,
          })
        )

        changeMasteryPoints(result, 0)

        expectMasteryPointsErrors(result, 'Below min rating')
        expect(result.current.hasError).toBeTruthy()
      })

      it('should bypass mastery point validations if no ratings', () => {
        const {result} = renderHook(() =>
          useRatings({
            initialRatings: null,
            initialMasteryPoints,
          })
        )

        changeMasteryPoints(result, 0)

        expectMasteryPointsErrors(result, null)
        expect(result.current.hasError).toBeFalsy()
      })
    })
  })

  describe('prepareRatings', () => {
    it('should add a key prop to each rating', () => {
      const result = prepareRatings(defaultRatings)
      expect(result[0].key).not.toBeNull()
      expect(result[1].key).not.toBeNull()
      expect(result[2].key).not.toBeNull()
      expect(result[3].key).not.toBeNull()
      expect(result[4].key).not.toBeNull()
    })

    it('should return an empty array if no ratings', () => {
      const result = prepareRatings()
      expect(result.length).toBe(0)
    })
  })
})
