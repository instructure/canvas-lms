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

import React from 'react'
import $ from 'jquery'
import {render} from '@testing-library/react'
import ColumnHeaders from '../ColumnHeaders'

const defaultProps = newProps => {
  const originalProps = {
    areAllItemsSelected: () => {},
    params: {},
    pathname: '/',
    query: {},
    toggleAllSelected: () => {},
    usageRightsRequiredForContext: false,
  }
  return {...originalProps, ...newProps}
}

const renderComponent = (updatedProps = {}) =>
  render(<ColumnHeaders {...defaultProps(updatedProps)} />)

describe('ColumnHeaders', () => {
  it('correctly assigns the appropriate hrefs', () => {
    const props = {
      query: {sort: 'something', order: 'asc'},
      pathname: '/some/path/to/files',
    }
    const {getByRole} = renderComponent(props)
    const nameLink = getByRole('link', {name: /Name/})
    const url = new URL(nameLink.href)
    expect(url.pathname).toEqual(props.pathname)
    expect(url.search).toEqual('?sort=name&order=desc')
  })

  describe('sort order message', () => {
    beforeEach(() => {
      $.screenReaderFlashMessage = jest.fn()
    })

    afterEach(() => {
      jest.restoreAllMocks()
    })

    describe('when no query is provided', () => {
      it('is not added to the flash_screenreader_holder', () => {
        renderComponent()
        expect($.screenReaderFlashMessage).toHaveBeenCalledTimes(0)
      })
    })

    describe('when a query is provided', () => {
      it('is added to the flash_screenreader_holder each time the query changes', () => {
        renderComponent()
        renderComponent({query: {sort: 'name', order: 'desc'}})
        renderComponent({query: {sort: 'name', order: 'asc'}})
        renderComponent({query: {sort: 'name', order: 'asc'}})
        renderComponent({query: {sort: 'created_at', order: 'asc'}})
        expect($.screenReaderFlashMessage).toHaveBeenCalledTimes(3)
      })
    })
  })

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
