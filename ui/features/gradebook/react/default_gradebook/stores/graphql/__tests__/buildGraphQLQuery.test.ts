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

import {encode, decode} from '../buildGraphQLQuery'

describe('buildGraphQLQuery encode/decode', () => {
  describe('round-trip encoding', () => {
    it('handles edge case user IDs', () => {
      const edgeCases = ['0', '1', '9007199254740991', '9007199254740992', '999999999999999999']

      edgeCases.forEach(userId => {
        expect(decode(encode(userId))).toBe(userId)
      })
    })

    it('preserves exact string format without numeric conversion', () => {
      const ids = ['1', '01', '001', '0001']
      const encoded = ids.map(encode)
      const decoded = encoded.map(decode)

      expect(decoded).toEqual(ids)
      expect(new Set(encoded).size).toBe(ids.length)
    })
  })

  describe('collision prevention', () => {
    it('ensures no collisions for 1000 sequential large user IDs', () => {
      const baseIdStr = '70530000000012000'
      const baseId = BigInt(baseIdStr)
      const userIds = Array.from({length: 1000}, (_, i) => (baseId + BigInt(i)).toString())

      const aliases = userIds.map(encode)
      const uniqueAliases = new Set(aliases)

      expect(uniqueAliases.size).toBe(userIds.length)

      const decodedIds = aliases.map(decode)
      expect(decodedIds).toEqual(userIds)
    })
  })

  describe('GraphQL alias validity', () => {
    it('creates valid GraphQL alias names', () => {
      const userIds = ['1', '999', '70530000000012622', '123456789012345678901234567890']

      userIds.forEach(userId => {
        const alias = encode(userId)
        expect(alias).toMatch(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
      })
    })
  })
})
