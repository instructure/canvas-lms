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

import {fireEvent, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {FAKE_FOLDERS_AND_FILES} from '../../../../fixtures/fakeData'
import {renderComponent} from './testUtils'

describe('FileFolderTable', () => {
  beforeEach(() => {
    fetchMock.get(/.*\/folders/, {
      body: FAKE_FOLDERS_AND_FILES,
      headers: {Link: '<p1url>; rel="current", <p2url>; rel="next", <p1url>; rel="first"'},
      status: 200,
    })
    fetchMock.get('p2url', {
      body: [],
      headers: {Link: '<p2url>; rel="current", <p1url>; rel="first"'},
      status: 200,
    })
  })

  afterEach(() => {
    fetchMock.restore()
  })

  describe('sort functionality', () => {
    it('sorts by Name ascending on initial load', async () => {
      const {findByTestId} = renderComponent()
      const nameHeader = await findByTestId('name')
      expect(nameHeader).toHaveAttribute('aria-sort', 'ascending')
    })
    it('sorts by column ascending when a column header is clicked', async () => {
      const {findByTestId} = renderComponent()
      const sizeHeader = await findByTestId('size')
      expect(sizeHeader).toHaveAttribute('aria-sort', 'none')
      fireEvent.click(sizeHeader.querySelector('button') as HTMLButtonElement)
      await waitFor(() => {
        expect(sizeHeader).toHaveAttribute('aria-sort', 'ascending')
      })
    })

    it('sorts by column descending when clicked twice', async () => {
      const {findByTestId} = renderComponent()
      const sizeHeader = await findByTestId('size')
      expect(sizeHeader).toHaveAttribute('aria-sort', 'none')
      fireEvent.click(sizeHeader.querySelector('button') as HTMLButtonElement)
      await waitFor(() => {
        expect(sizeHeader).toHaveAttribute('aria-sort', 'ascending')
      })
      fireEvent.click(sizeHeader.querySelector('button') as HTMLButtonElement)
      await waitFor(() => {
        expect(sizeHeader).toHaveAttribute('aria-sort', 'descending')
      })
    })

    it('resets to ascending sort when column header is clicked a third time', async () => {
      const {findByTestId} = renderComponent()
      const sizeHeader = await findByTestId('size')
      expect(sizeHeader).toHaveAttribute('aria-sort', 'none')
      fireEvent.click(sizeHeader.querySelector('button') as HTMLButtonElement)
      await waitFor(() => {
        expect(sizeHeader).toHaveAttribute('aria-sort', 'ascending')
      })
      fireEvent.click(sizeHeader.querySelector('button') as HTMLButtonElement)
      await waitFor(() => {
        expect(sizeHeader).toHaveAttribute('aria-sort', 'descending')
      })
      fireEvent.click(sizeHeader.querySelector('button') as HTMLButtonElement)
      await waitFor(() => {
        expect(sizeHeader).toHaveAttribute('aria-sort', 'ascending')
      })
    })

    it('calls callbacks to be called on api response', async () => {
      const onPaginationLinkChange = jest.fn()
      const onLoadingStatusChange = jest.fn()
      renderComponent({
        onPaginationLinkChange,
        onLoadingStatusChange,
      })
      await waitFor(() => {
        expect(onPaginationLinkChange).toHaveBeenCalledWith({
          current: 'p1url',
          next: 'p2url',
          first: 'p1url',
        })
      })

      expect(onLoadingStatusChange).toHaveBeenCalledWith(false)
    })
  })
})
