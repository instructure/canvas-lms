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

import React from 'react'
import {render} from '@testing-library/react'
import {AccountNavigation} from '../AccountNavigation'

describe('AccountNavigation', () => {
  const props = {onPageClick: jest.fn()}

  describe('onPageClick called with page changes', () => {
    afterEach(() => {
      jest.clearAllMocks()
    })

    it('calls onPageClick with index when a page is clicked', () => {
      const {getByText} = render(<AccountNavigation {...props} currentPage={1} pageCount={2} />)
      const nextPage = getByText(2)
      nextPage.click()
      expect(props.onPageClick).toHaveBeenCalledWith(2)
    })

    it('does not call render again if current page number is clicked', () => {
      const {getByText} = render(<AccountNavigation {...props} currentPage={1} pageCount={1} />)
      const currPage = getByText(1)
      currPage.click()
      expect(props.onPageClick).not.toHaveBeenCalled()
    })
  })

  describe('Correct number of page buttons load', () => {
    afterEach(() => {
      jest.clearAllMocks()
    })

    it('renders one page button when pageCount is 1', () => {
      const {getByText, queryByText} = render(
        <AccountNavigation {...props} currentPage={1} pageCount={1} />
      )
      expect(getByText(1)).toBeInTheDocument()
      expect(queryByText(2)).not.toBeInTheDocument()
      expect(queryByText(0)).not.toBeInTheDocument()
    })

    it('renders page buttons 1-3 when page count is 3', () => {
      const {getByText, queryByText} = render(
        <AccountNavigation {...props} currentPage={1} pageCount={3} />
      )
      expect(getByText(1)).toBeInTheDocument()
      expect(getByText(2)).toBeInTheDocument()
      expect(getByText(3)).toBeInTheDocument()
      expect(queryByText(4)).not.toBeInTheDocument()
      expect(queryByText(0)).not.toBeInTheDocument()
    })
  })
})
