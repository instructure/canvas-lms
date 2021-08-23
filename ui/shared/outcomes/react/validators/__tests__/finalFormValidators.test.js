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

import {composeValidators, maxLengthValidator, requiredValidator} from '../finalFormValidators'

describe('Final Form Validators', () => {
  describe('requiredValidator', () => {
    it('returns proper error message if value is empty', () => {
      expect(requiredValidator('')).toEqual('This field is required')
      expect(requiredValidator(undefined)).toEqual('This field is required')
      expect(requiredValidator(null)).toEqual('This field is required')
    })

    it('returns null', () => {
      expect(requiredValidator(' ')).toEqual(null)
      expect(requiredValidator('test')).toEqual(null)
    })
  })

  describe('maxLengthValidator', () => {
    it('returns proper error message if value is max than length', () => {
      expect(maxLengthValidator(10)('a'.repeat(11))).toEqual('Must be 10 characters or less')
    })

    it('returns null', () => {
      expect(maxLengthValidator(10)('a'.repeat(10))).toEqual(null)
      expect(maxLengthValidator(10)('a'.repeat(5))).toEqual(null)
      expect(maxLengthValidator(10)('')).toEqual(null)
      expect(maxLengthValidator(10)(undefined)).toEqual(null)
      expect(maxLengthValidator(10)(null)).toEqual(null)
    })
  })
  describe('composeValidators', () => {
    const validator = composeValidators(requiredValidator, maxLengthValidator(10))

    it('creates a validator with multiple validators', () => {
      expect(validator('a'.repeat(10))).toEqual(null)
      expect(validator('a'.repeat(5))).toEqual(null)
      expect(validator('a'.repeat(11))).toEqual('Must be 10 characters or less')
      expect(validator('')).toEqual('This field is required')
      expect(validator(undefined)).toEqual('This field is required')
      expect(validator(null)).toEqual('This field is required')
    })
  })
})
