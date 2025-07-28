/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import OutlierScoreHelper, {isUnusuallyHigh} from '../OutlierScoreHelper'
import GRADEBOOK_TRANSLATIONS from '@canvas/grading/GradebookTranslations'

describe('#hasWarning', () => {
  test('returns true for exactly 1.5 times points possible', () => {
    expect(new OutlierScoreHelper(150, 100).hasWarning()).toBeTruthy()
  })

  test('returns true when above 1.5 times and decimal is present', () => {
    expect(new OutlierScoreHelper(150.01, 100).hasWarning()).toBeTruthy()
  })

  test('returns true when value is negative', () => {
    expect(new OutlierScoreHelper(-1, 100).hasWarning()).toBeTruthy()
  })

  test('returns false when value is less than 1.5 times', () => {
    expect(new OutlierScoreHelper(149.99, 100).hasWarning()).toBeFalsy()
  })

  test('returns false for 0 points', () => {
    expect(new OutlierScoreHelper(0, 100).hasWarning()).toBeFalsy()
  })

  test('returns false for 0 points possible', () => {
    expect(new OutlierScoreHelper(10, 0).hasWarning()).toBeFalsy()
  })

  test('returns false for null score', () => {
    expect(new OutlierScoreHelper(null, 100).hasWarning()).toBeFalsy()
  })

  test('returns false for null points possible', () => {
    expect(new OutlierScoreHelper(10, null).hasWarning()).toBeFalsy()
  })

  test('returns false for NaN score', () => {
    expect(new OutlierScoreHelper(NaN, 100).hasWarning()).toBeFalsy()
  })

  test('returns false for NaN pointsPossible', () => {
    expect(new OutlierScoreHelper(10, NaN).hasWarning()).toBeFalsy()
  })
})

describe('#isUnusuallyHigh', () => {
  test('returns true for exactly 1.5 times points possible', () => {
    expect(isUnusuallyHigh(150, 100)).toBeTruthy()
  })

  test('returns true when above 1.5 times and decimal is present', () => {
    expect(isUnusuallyHigh(150.01, 100)).toBeTruthy()
  })

  test('returns false when value is less than 1.5 times', () => {
    expect(isUnusuallyHigh(149.99, 100)).toBeFalsy()
  })

  test('returns false for 0 points', () => {
    expect(isUnusuallyHigh(0, 100)).toBeFalsy()
  })

  test('returns false for 0 points possible', () => {
    expect(isUnusuallyHigh(10, 0)).toBeFalsy()
  })

  test('returns false for null score', () => {
    expect(isUnusuallyHigh(null, 100)).toBeFalsy()
  })

  test('returns false for null points possible', () => {
    expect(isUnusuallyHigh(10, null)).toBeFalsy()
  })

  test('returns false for NaN score', () => {
    expect(isUnusuallyHigh(NaN, 100)).toBeFalsy()
  })

  test('returns false for NaN pointsPossible', () => {
    expect(isUnusuallyHigh(10, NaN)).toBeFalsy()
  })
})

describe('#warningMessage', () => {
  let tooManyPointsWarning, negativePointsWarning

  beforeEach(() => {
    tooManyPointsWarning = GRADEBOOK_TRANSLATIONS.submission_too_many_points_warning
    negativePointsWarning = GRADEBOOK_TRANSLATIONS.submission_negative_points_warning
  })

  test('positive score outside 1.5 multiplier returns too many points warning', () => {
    const outlierScore = new OutlierScoreHelper(150, 100)
    expect(outlierScore.warningMessage()).toBe(tooManyPointsWarning)
  })

  test('negative score returns negative points warning', () => {
    const outlierScore = new OutlierScoreHelper(-1, 100)
    expect(outlierScore.warningMessage()).toBe(negativePointsWarning)
  })

  test('score within range returns null', () => {
    const outlierScore = new OutlierScoreHelper(100, 100)
    expect(outlierScore.warningMessage()).toBeNull()
  })
})
