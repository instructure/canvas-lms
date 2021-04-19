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

import {isValid} from '../validateReturnToURL'

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

    test('returns false for data: protocol', () => {
      expect(isValid('data:text/html;base64,PHNjcmlwdD5hbGVydCgiaGkiKTwvc2NyaXB0Pg==')).toEqual(
        false
      )
      expect(isValid('  data:text/html;base64,PHNjcmlwdD5hbGVydCgiaGkiKTwvc2NyaXB0Pg==')).toEqual(
        false
      )
      expect(isValid('DaTa:text/html;base64,PHNjcmlwdD5hbGVydCgiaGkiKTwvc2NyaXB0Pg==')).toEqual(
        false
      )
    })

    test('returns true for relative urls', () => {
      expect(isValid('/')).toEqual(true)
    })

    test('returns true for absolute urls in the same origin', () => {
      expect(isValid(window.location.origin + '/courses/1/assignments')).toEqual(true)
    })

    test('returns false for absolute urls in a different origin', () => {
      expect(isValid('http://evil.com')).toEqual(false)
    })
  })
})
