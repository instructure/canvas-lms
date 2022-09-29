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

import {processRatingsAndMastery} from '../ratingsHelpers'

describe('Ratings Helpers', () => {
  const testMasteryPoints = 3
  const testRatings = [
    {
      description: 'rating 1 description',
      points: 1.25,
    },
    {
      description: 'rating 2 description',
      points: '2.50',
    },
    {
      description: 'rating 3 description',
      points: 3,
    },
  ]

  describe('processRatingsAndMastery', () => {
    it('processes masteryPoints provided as number', () => {
      const {masteryPoints} = processRatingsAndMastery(testRatings, testMasteryPoints)
      expect(masteryPoints).toEqual(3)
    })

    it('processes masteryPoints provided as string', () => {
      const {masteryPoints} = processRatingsAndMastery(testRatings, '123.45')
      expect(masteryPoints).toEqual(123.45)
    })

    it('rounds masteryPoints to 2 decimal places', () => {
      const {masteryPoints} = processRatingsAndMastery(testRatings, 3.125)
      expect(masteryPoints).toEqual(3.13)
    })

    it('processes points provided as number', () => {
      const {ratings} = processRatingsAndMastery(testRatings, testMasteryPoints)
      expect(ratings[0].points).toEqual(1.25)
    })

    it('processes points provided as string', () => {
      const {ratings} = processRatingsAndMastery(testRatings, testMasteryPoints)
      expect(ratings[1].points).toEqual(2.5)
    })
  })
})
