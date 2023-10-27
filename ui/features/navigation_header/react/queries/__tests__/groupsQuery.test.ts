/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {groupFilter} from '../groupsQuery'

describe('groupsQuery', () => {
  describe('groupFilter', () => {
    it('returns true when group.can_access is true and group.concluded is false', () => {
      expect(groupFilter({can_access: true, concluded: false})).toBe(true)
    })

    it('returns false when group.can_access is false', () => {
      expect(groupFilter({can_access: false, concluded: false})).toBe(false)
    })

    it('returns false when group.concluded is true', () => {
      expect(groupFilter({can_access: true, concluded: true})).toBe(false)
    })
  })
})
