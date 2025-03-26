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

import {scoreFromPercent, scaleScore} from '../scoreCalculation'

describe ('scoreCalculation', () => {

    describe ('scoreFromPercent', () => {

        it('uses outcome.mastery_points when outcome.points_possible <= 0', () => {
            const result = scoreFromPercent(0.5, {mastery_points: 10, points_possible: 0}, 0)
            expect(result).toBe(5)
        })

        it('uses outcome.points_possible when outcome.points_possible > 0', () => {
            const result = scoreFromPercent(0.5, {mastery_points: 10, points_possible: 20}, 0)
            expect(result).toBe(10)
        })

        it(`uses
            pointsPossibleFromOutcomeRatingsFromRubric
            when pointsPossibleFromOutcomeRatingsFromRubric is a number
            and is > 0`, () => {
            const result = scoreFromPercent(0.5, {mastery_points: 10, points_possible: 20}, 8)
            expect(result).toBe(4)
        })

        it(`does not use
            pointsPossibleFromOutcomeRatingsFromRubric
            when pointsPossibleFromOutcomeRatingsFromRubric is not a number`, () => {
            const result = scoreFromPercent(0.5, {mastery_points: 10, points_possible: 20}, 'a')
            expect(result).toBe(10)
        })

        it(`does not use
            pointsPossibleFromOutcomeRatingsFromRubric
            when pointsPossibleFromOutcomeRatingsFromRubric is <= 0`, () => {
            const result = scoreFromPercent(0.5, {mastery_points: 10, points_possible: 20}, 0)
            expect(result).toBe(10)
        })

    })

    describe ('scaleScore', () => {

        it('uses outcome.mastery_points when outcome.points_possible <= 0', () => {
            const result = scaleScore(5, 10, {mastery_points: 10, points_possible: 0}, 0)
            expect(result).toBe(5)
        })

        it('uses outcome.points_possible when outcome.points_possible > 0', () => {
            const result = scaleScore(5, 10, {mastery_points: 10, points_possible: 4}, 0)
            expect(result).toBe(2)
        })

        it(`uses pointsPossibleFromOutcomeRatingsFromRubric
            when pointsPossibleFromOutcomeRatingsFromRubric is a number > 0`, () => {
            const result = scaleScore(6, 2, {mastery_points: 10, points_possible: 4}, 2)
            expect(result).toBe(6)
        })

        it(`does not use pointsPossibleFromOutcomeRatingsFromRubric
            when pointsPossibleFromOutcomeRatingsFromRubric is not a number`, () => {
            const result = scaleScore(6, 2, {mastery_points: 10, points_possible: 2}, 's')
            expect(result).toBe(6)
        })
    })
})
