/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import LoadMore from '../LoadMore'

describe('LoadMore', () => {
  const defaultProps = {
    hasMore: false,
    loadMore() {},
    isLoading: false,
  }

  it('renders the load more component', () => {
    const {container} = render(<LoadMore {...defaultProps} />)
    expect(container.firstChild).toBeInTheDocument()
  })

  it('function is called on load more link click', async () => {
    const user = userEvent.setup()
    const mockLoadMore = jest.fn()
    const {container} = render(
      <LoadMore {...defaultProps} hasMore={true} loadMore={mockLoadMore} />,
    )
    const button = container.querySelector('.Button--link')
    await user.click(button)
    expect(mockLoadMore).toHaveBeenCalled()
  })
})
