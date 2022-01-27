/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {convertRatings, prepareRatings} from '../ratingsHelpers'

describe('Ratings Helpers', () => {
  const testMasteryPoints = 3
  const testRatings = [
    {
      description: 'rating 1 description',
      points: 1.25
    },
    {
      description: 'rating 2 description',
      points: '2.50'
    },
    {
      description: 'rating 3 description',
      points: 3
    }
  ]
  const testConvertRatings = testRatings.map(({description, points}) => ({
    description,
    points,
    mastery: Number(points) === Number(testMasteryPoints)
  }))

  describe('convertRatings', () => {
    it('converts masteryPoints', () => {
      const {masteryPoints} = convertRatings(testConvertRatings)
      expect(masteryPoints).toEqual(3)
    })

    it('converts points provided as number', () => {
      const {ratings} = convertRatings(testConvertRatings)
      expect(ratings[0].points).toEqual(1.25)
    })

    it('converts points provided as string', () => {
      const {ratings} = convertRatings(testConvertRatings)
      expect(ratings[1].points).toEqual(2.5)
    })
  })

  describe('prepareRatings', () => {
    it('adds mastery prop to ratings', () => {
      const result = prepareRatings(testRatings, testMasteryPoints)
      expect(result[0].mastery).toBeFalsy()
      expect(result[1].mastery).toBeFalsy()
      expect(result[2].mastery).toBeTruthy()
    })

    it('adds key prop to ratings', () => {
      const result = prepareRatings(testRatings, testMasteryPoints)
      expect(result[0].key).not.toBeNull()
      expect(result[1].key).not.toBeNull()
      expect(result[2].key).not.toBeNull()
    })

    it('handles null ratings argument', () => {
      const result = prepareRatings(null, testMasteryPoints)
      expect(result.length).toBe(0)
    })
  })
})
