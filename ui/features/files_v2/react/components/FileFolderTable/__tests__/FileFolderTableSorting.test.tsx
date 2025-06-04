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

import {fireEvent, screen} from '@testing-library/react'
import {renderComponent} from './testUtils'

describe('FileFolderTable', () => {
  let flashElements: any
  const onSortChange = jest.fn()
  beforeEach(() => {
    flashElements = document.createElement('div')
    flashElements.setAttribute('id', 'flash_screenreader_holder')
    flashElements.setAttribute('role', 'alert')
    document.body.appendChild(flashElements)
  })

  afterEach(() => {
    onSortChange.mockClear()
    document.body.removeChild(flashElements)
    flashElements = undefined
  })

  describe('sort functionality', () => {
    const title = 'name'

    describe('when sort is set to ascending', () => {
      it('displays as ascending', async () => {
        const {findByTestId} = renderComponent({sort: {by: title, direction: 'asc'}})
        const header = await findByTestId(title)
        expect(header).toHaveAttribute('aria-sort', 'ascending')
      })

      it('clicking on same header calls onSortChange with descending', async () => {
        const {findByTestId} = renderComponent({sort: {by: title, direction: 'asc'}, onSortChange})
        const header = await findByTestId(title)
        fireEvent.click(header.querySelector('button') as HTMLButtonElement)
        expect(onSortChange).toHaveBeenCalledWith({by: title, direction: 'desc'})
      })

      it('has correct screen reader label', async () => {
        const {findByText} = renderComponent({sort: {by: title, direction: 'asc'}})
        const header = await findByText('Sorted by name')
        expect(header).toBeInTheDocument()
      })
    })

    describe('when sort is set to descending', () => {
      it('displays as descending', async () => {
        const {findByTestId} = renderComponent({sort: {by: title, direction: 'desc'}})
        const header = await findByTestId(title)
        expect(header).toHaveAttribute('aria-sort', 'descending')
      })

      it('clicking on same header calls onSortChange with ascending', async () => {
        const {findByTestId} = renderComponent({sort: {by: title, direction: 'desc'}, onSortChange})
        const header = await findByTestId(title)
        fireEvent.click(header.querySelector('button') as HTMLButtonElement)
        expect(onSortChange).toHaveBeenCalledWith({by: title, direction: 'asc'})
      })

      it('has correct screen reader label', async () => {
        const {findByText} = renderComponent({sort: {by: title, direction: 'desc'}})
        const header = await findByText('Sorted by name')
        expect(header).toBeInTheDocument()
      })
    })

    describe('unsorted header', () => {
      const unsortedTitle = 'created_at'
      let findByTestId: ReturnType<typeof renderComponent>['findByTestId']
      beforeEach(() => {
        findByTestId = renderComponent({
          sort: {by: title, direction: 'desc'},
          onSortChange,
        }).findByTestId
      })

      it('displays as none', async () => {
        const header = await findByTestId(unsortedTitle)
        expect(header).toHaveAttribute('aria-sort', 'none')
      })

      it('clicking on header calls onSortChange with ascending', async () => {
        const header = await findByTestId(unsortedTitle)
        fireEvent.click(header.querySelector('button') as HTMLButtonElement)
        expect(onSortChange).toHaveBeenCalledWith({by: unsortedTitle, direction: 'asc'})
      })
    })

    it('updates sorting screenreader alert', async () => {
      renderComponent({sort: {by: title, direction: 'asc'}})
      // this includes sr alert and the table caption
      const alert = await screen.findAllByText(
        new RegExp(`sorted by ${title} in ascending order`, 'i'),
      )
      expect(alert).toHaveLength(2)
    })
  })
})
