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

import {getForceGqlParam, shouldUseGraphQL} from '../forceGqlParam'

describe('forceGqlParam', () => {
  const mockLocationSearch = (search: string) => {
    const url = `${window.location.origin}${window.location.pathname}${search}`
    window.history.pushState({}, '', url)
  }

  describe('getForceGqlParam', () => {
    it('returns true when force_gql=true', () => {
      mockLocationSearch('?force_gql=true')
      expect(getForceGqlParam()).toBe(true)
    })

    it('returns false when force_gql=false', () => {
      mockLocationSearch('?force_gql=false')
      expect(getForceGqlParam()).toBe(false)
    })

    it('returns null when force_gql is not present', () => {
      mockLocationSearch('')
      expect(getForceGqlParam()).toBe(null)
    })

    it('returns null when force_gql has invalid value', () => {
      mockLocationSearch('?force_gql=invalid')
      expect(getForceGqlParam()).toBe(null)
    })
  })

  describe('shouldUseGraphQL', () => {
    it('returns true when force_gql=true, regardless of backend setting', () => {
      mockLocationSearch('?force_gql=true')
      expect(shouldUseGraphQL(false)).toBe(true)
      expect(shouldUseGraphQL(true)).toBe(true)
    })

    it('returns false when force_gql=false, regardless of backend setting', () => {
      mockLocationSearch('?force_gql=false')
      expect(shouldUseGraphQL(false)).toBe(false)
      expect(shouldUseGraphQL(true)).toBe(false)
    })

    it('returns backend setting when force_gql is not present', () => {
      mockLocationSearch('')
      expect(shouldUseGraphQL(true)).toBe(true)
      expect(shouldUseGraphQL(false)).toBe(false)
    })

    it('returns backend setting when force_gql is invalid', () => {
      mockLocationSearch('?force_gql=invalid')
      expect(shouldUseGraphQL(true)).toBe(true)
      expect(shouldUseGraphQL(false)).toBe(false)
    })
  })
})
