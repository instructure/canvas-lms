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

import {findRating} from '../ratings'
import {Rating} from '../../types/rollup'

describe('findRating', () => {
  const ratings: Rating[] = [
    {
      points: 5,
      color: '#00FF00',
      description: 'Excellent',
      mastery: true,
    },
    {
      points: 3,
      color: '#FFFF00',
      description: 'Proficient',
      mastery: false,
    },
    {
      points: 1,
      color: '#FF0000',
      description: 'Developing',
      mastery: false,
    },
    {
      points: 0,
      color: '#000000',
      description: 'Not Yet',
      mastery: false,
    },
  ]

  describe('exact matches', () => {
    it('returns the rating with exact matching points', () => {
      expect(findRating(ratings, 5)).toEqual(ratings[0])
      expect(findRating(ratings, 3)).toEqual(ratings[1])
      expect(findRating(ratings, 1)).toEqual(ratings[2])
      expect(findRating(ratings, 0)).toEqual(ratings[3])
    })
  })

  describe('scores exceeding highest rating', () => {
    it('returns the highest rating when score exceeds all ratings', () => {
      expect(findRating(ratings, 10)).toEqual(ratings[0])
      expect(findRating(ratings, 6)).toEqual(ratings[0])
      expect(findRating(ratings, 5.5)).toEqual(ratings[0])
    })
  })

  describe('scores between ratings', () => {
    it('returns the lower rating when score falls between two ratings', () => {
      // Score 4 falls between 5 and 3, should return rating with points 3
      expect(findRating(ratings, 4)).toEqual(ratings[1])
      expect(findRating(ratings, 4.5)).toEqual(ratings[1])
      expect(findRating(ratings, 3.1)).toEqual(ratings[1])

      // Score 2 falls between 3 and 1, should return rating with points 1
      expect(findRating(ratings, 2)).toEqual(ratings[2])
      expect(findRating(ratings, 2.5)).toEqual(ratings[2])
      expect(findRating(ratings, 1.1)).toEqual(ratings[2])

      // Score 0.5 falls between 1 and 0, should return rating with points 0
      expect(findRating(ratings, 0.5)).toEqual(ratings[3])
      expect(findRating(ratings, 0.1)).toEqual(ratings[3])
    })
  })

  describe('fallback to lowest rating', () => {
    it('returns the lowest rating when no match is found', () => {
      const ratingsWithoutZero: Rating[] = [
        {points: 5, color: '#00FF00', description: 'Excellent', mastery: true},
        {points: 3, color: '#FFFF00', description: 'Proficient', mastery: false},
        {points: 1, color: '#FF0000', description: 'Developing', mastery: false},
      ]

      // Score -1 doesn't match any rating, should return lowest (points: 1)
      expect(findRating(ratingsWithoutZero, -1)).toEqual(ratingsWithoutZero[2])
    })
  })

  describe('edge cases', () => {
    it('handles a single rating', () => {
      const singleRating: Rating[] = [
        {points: 3, color: '#FFFF00', description: 'Pass', mastery: true},
      ]

      expect(findRating(singleRating, 5)).toEqual(singleRating[0])
      expect(findRating(singleRating, 3)).toEqual(singleRating[0])
      expect(findRating(singleRating, 0)).toEqual(singleRating[0])
    })

    it('handles two ratings', () => {
      const twoRatings: Rating[] = [
        {points: 3, color: '#00FF00', description: 'Pass', mastery: true},
        {points: 0, color: '#FF0000', description: 'Fail', mastery: false},
      ]

      expect(findRating(twoRatings, 5)).toEqual(twoRatings[0]) // Above highest
      expect(findRating(twoRatings, 3)).toEqual(twoRatings[0]) // Exact match high
      expect(findRating(twoRatings, 2)).toEqual(twoRatings[1]) // Between
      expect(findRating(twoRatings, 0)).toEqual(twoRatings[1]) // Exact match low
      expect(findRating(twoRatings, -1)).toEqual(twoRatings[1]) // Below lowest
    })

    it('handles decimal scores', () => {
      expect(findRating(ratings, 3.5)).toEqual(ratings[1])
      expect(findRating(ratings, 2.75)).toEqual(ratings[2])
      expect(findRating(ratings, 0.25)).toEqual(ratings[3])
    })

    it('handles negative scores', () => {
      expect(findRating(ratings, -1)).toEqual(ratings[3])
      expect(findRating(ratings, -100)).toEqual(ratings[3])
    })
  })

  describe('ratings order validation', () => {
    it('works correctly when ratings are sorted in descending order by points', () => {
      const descendingRatings: Rating[] = [
        {points: 10, color: '#00FF00', description: 'A', mastery: true},
        {points: 8, color: '#FFFF00', description: 'B', mastery: false},
        {points: 6, color: '#FFA500', description: 'C', mastery: false},
        {points: 4, color: '#FF0000', description: 'D', mastery: false},
      ]

      expect(findRating(descendingRatings, 11)).toEqual(descendingRatings[0])
      expect(findRating(descendingRatings, 10)).toEqual(descendingRatings[0])
      expect(findRating(descendingRatings, 9)).toEqual(descendingRatings[1])
      expect(findRating(descendingRatings, 8)).toEqual(descendingRatings[1])
      expect(findRating(descendingRatings, 7)).toEqual(descendingRatings[2])
      expect(findRating(descendingRatings, 6)).toEqual(descendingRatings[2])
      expect(findRating(descendingRatings, 5)).toEqual(descendingRatings[3])
      expect(findRating(descendingRatings, 4)).toEqual(descendingRatings[3])
      expect(findRating(descendingRatings, 3)).toEqual(descendingRatings[3])
    })
  })
})
