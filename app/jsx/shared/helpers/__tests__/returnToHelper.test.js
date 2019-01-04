/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import { isValid } from '../returnToHelper'

describe('returnToHelper', () => {
  describe('isValid', () => {
    test('returns false if url is falsy', () => {
      expect(isValid('')).toEqual(false)
      expect(isValid(null)).toEqual(false)
      expect(isValid(undefined)).toEqual(false)
    })

    test('returns false for javascript protocol', () => {
      // eslint-disable-next-line no-script-url
      expect(isValid('javascript:alert("shame!")')).toEqual(false)
      expect(isValid('  javascript:alert("this would still run")')).toEqual(false)
      // eslint-disable-next-line no-script-url
      expect(isValid('JaVaScRiPt:alert("nice try")')).toEqual(false)
    })

    test('returns true for other urls', () => {
      expect(isValid('https://github.com')).toEqual(true)
      expect(isValid('/')).toEqual(true)
    })
  })
})
