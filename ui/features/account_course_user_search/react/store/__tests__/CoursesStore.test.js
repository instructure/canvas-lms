/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import CoursesStore from '../CoursesStore'

describe('CoursesStore', () => {
  describe('normalizeParams', () => {
    test('omits search_term argument if not given', () => {
      const {search_term} = CoursesStore.normalizeParams({})
      expect(search_term).toBeUndefined()
    })

    test('omits search_term argument if blank', () => {
      const {search_term} = CoursesStore.normalizeParams({search_term: ''})
      expect(search_term).toBeUndefined()
    })

    test('strips whitespace from search_term argument', () => {
      const {search_term} = CoursesStore.normalizeParams({search_term: ' foo  '})
      expect(search_term).toEqual('foo')
    })
  })
})
