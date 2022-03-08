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

import ColumnHeaders from '../ColumnHeaders'

describe('ColumnHeaders', () => {
  describe('queryParamsFor method', () => {
    const {queryParamsFor} = ColumnHeaders.prototype

    describe('correctly determines query params when', () => {
      const SORT_UPDATED_AT_DESC = {sort: 'updated_at', order: 'desc'}
      const SORT_UPDATED_AT_ASC = {sort: 'updated_at', order: 'asc'}

      it('headers were previously not sorted', () => {
        const queryParams = queryParamsFor({}, 'updated_at')
        expect(queryParams).toEqual(SORT_UPDATED_AT_DESC)
      })

      it('swapping sort columns', () => {
        const queryParams = queryParamsFor({sort: 'created_at', order: 'desc'}, 'updated_at')
        expect(queryParams).toEqual(SORT_UPDATED_AT_DESC)
      })

      it('swapping sort order from ascending to descending', () => {
        const queryParams = queryParamsFor(SORT_UPDATED_AT_ASC, 'updated_at')
        expect(queryParams).toEqual(SORT_UPDATED_AT_DESC)
      })

      it('swapping sort order from descending to ascending', () => {
        const queryParams = queryParamsFor(SORT_UPDATED_AT_DESC, 'updated_at')
        expect(queryParams).toEqual(SORT_UPDATED_AT_ASC)
      })
    })
  })
})
