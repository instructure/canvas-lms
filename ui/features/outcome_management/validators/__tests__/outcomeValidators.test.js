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

import {titleValidator, displayNameValidator} from '../outcomeValidators'

describe('outcomeValidators', () => {
  describe('titleValidators', () => {
    it('returns proper error message if title is empty', () => {
      expect(titleValidator('')).toEqual('Cannot be blank')
    })

    it('returns proper error message if title includes only spaces', () => {
      expect(titleValidator(' '.repeat(3))).toEqual('Cannot be blank')
    })

    it('returns proper error message if title is > 255 chars long', () => {
      expect(titleValidator('a'.repeat(256))).toEqual('Must be 255 characters or less')
    })

    it('returns empty string if title is valid', () => {
      expect(titleValidator('abc')).toEqual('')
    })
  })

  describe('displayNameValidators', () => {
    it('generates proper error message if displayName is > 255 chars long', () => {
      expect(displayNameValidator('a'.repeat(256))).toEqual('Must be 255 characters or less')
    })

    it('returns empty string if displayName is valid', () => {
      expect(displayNameValidator('abc')).toEqual('')
    })
  })
})
