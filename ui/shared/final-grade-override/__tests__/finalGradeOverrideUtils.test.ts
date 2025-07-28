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

import {finalGradeOverrideUtils} from '../utils'

describe('restrictToTwoDigitsAfterSeparator', () => {
  describe('non numeric input', () => {
    it('returns the given value', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('abc')
      expect(result).toEqual('abc')
    })
  })

  describe('no separator', () => {
    it('returns the given value', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123')
      expect(result).toEqual('123')
    })
  })

  describe('decimal point separator', () => {
    it('handles a separator with nothing after it', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123.')
      expect(result).toEqual('123.')
    })

    it('returns the given value when there are less than 2 digits after the separator', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123.1')
      expect(result).toEqual('123.1')
    })

    it('returns the given value when there are exactly 2 digits after the separator', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123.12')
      expect(result).toEqual('123.12')
    })

    it('truncates the value when there are more than 2 digits after the separator', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123.123')
      expect(result).toEqual('123.12')
    })

    it('does not truncate when the value ends in a percent sign', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123.123%')
      expect(result).toEqual('123.123%')
    })

    it('handles leading whitespace', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('  123.123')
      expect(result).toEqual('  123.12')
    })

    it('handles trailing whitespace', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123.123  ')
      expect(result).toEqual('123.12  ')
    })

    it('handles signed negative values', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('-123.123')
      expect(result).toEqual('-123.12')
    })

    it('handles signed positive values', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('+123.123')
      expect(result).toEqual('+123.12')
    })
  })

  describe('comma separator', () => {
    it('handles a separator with nothing after it', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123,')
      expect(result).toEqual('123,')
    })

    it('returns the given value when there are less than 2 digits after the separator', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123,1')
      expect(result).toEqual('123,1')
    })

    it('returns the given value when there are exactly 2 digits after the separator', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123,12')
      expect(result).toEqual('123,12')
    })

    it('truncates the value when there are more than 2 digits after the separator', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123,123')
      expect(result).toEqual('123,12')
    })

    it('does not truncate when the value ends in a percent sign', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123,123%')
      expect(result).toEqual('123,123%')
    })

    it('handles leading whitespace', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('  123,123')
      expect(result).toEqual('  123,12')
    })

    it('handles trailing whitespace', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('123,123  ')
      expect(result).toEqual('123,12  ')
    })

    it('handles signed negative values', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('-123,123')
      expect(result).toEqual('-123,12')
    })

    it('handles signed positive values', () => {
      const result = finalGradeOverrideUtils.restrictToTwoDigitsAfterSeparator('+123,123')
      expect(result).toEqual('+123,12')
    })
  })
})
