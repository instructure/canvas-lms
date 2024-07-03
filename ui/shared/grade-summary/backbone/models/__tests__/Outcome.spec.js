/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import Outcome from '../Outcome'

describe('Outcome', () => {
  test('#status should be mastery if the score equals the mastery points', () => {
    const outcome = new Outcome({score: 3, mastery_points: 3})
    expect(outcome.status()).toBe('mastery')
  })

  test('#status should be mastery if the score is greater than the mastery points', () => {
    const outcome = new Outcome({score: 4, mastery_points: 3})
    expect(outcome.status()).toBe('mastery')
  })

  test('#status should be exceeds if the score is 150% or more of mastery points', () => {
    const outcome = new Outcome({score: 4.5, mastery_points: 3})
    expect(outcome.status()).toBe('exceeds')
  })

  test('#status should be near if the score is greater than half the mastery points', () => {
    const outcome = new Outcome({score: 2, mastery_points: 3})
    expect(outcome.status()).toBe('near')
  })

  test('#status should be remedial if the score is less than half the mastery points', () => {
    const outcome = new Outcome({score: 1, mastery_points: 3})
    expect(outcome.status()).toBe('remedial')
  })

  test('#status should accurately reflect the scaled aggregate score on question bank results', () => {
    const outcome = new Outcome({
      percent: 0.6,
      score: 0,
      mastery_points: 3,
      points_possible: 5,
      question_bank_result: true,
    })
    expect(outcome.status()).toBe('mastery')
  })

  test('#status should be undefined if there is no score', () => {
    const outcome = new Outcome({mastery_points: 3})
    expect(outcome.status()).toBe('undefined')
  })

  test('#scaledScore should fall back to mastery score if points possible is zero', () => {
    const outcome = new Outcome({
      percent: 0.7,
      score: 0,
      mastery_points: 3,
      points_possible: 0,
      question_bank_result: true,
    })
    expect(outcome.roundedScore()).toBe(2.1)
  })

  test('#scaledScore should fall back to mastery score if points possible is less than zero', () => {
    const outcome = new Outcome({
      percent: 0.7,
      score: 0,
      mastery_points: 3,
      points_possible: -1,
      question_bank_result: true,
    })
    expect(outcome.roundedScore()).toBe(2.1)
  })

  test("#percentProgress should be zero if score isn't defined", () => {
    const outcome = new Outcome({points_possible: 3})
    expect(outcome.percentProgress()).toBe(0)
  })

  test("#percentProgress should be score over points possible if 'percent' is not defined", () => {
    const outcome = new Outcome({score: 5, points_possible: 10})
    expect(outcome.percentProgress()).toBe(50)
  })

  test("#percentProgress should be percentage of points possible if 'percent' is defined", () => {
    const outcome = new Outcome({score: 5, points_possible: 10, percent: 0.6})
    expect(outcome.percentProgress()).toBe(60)
  })

  test('#masteryPercent should be mastery_points over points possible', () => {
    const outcome = new Outcome({mastery_points: 5, points_possible: 10})
    expect(outcome.masteryPercent()).toBe(50)
  })

  test('#parse', () => {
    const outcome = new Outcome()
    const parsed = outcome.parse({submitted_or_assessed_at: '2015-04-24T19:27:54Z'})
    expect(typeof parsed.submitted_or_assessed_at).toBe('object')
  })
})
