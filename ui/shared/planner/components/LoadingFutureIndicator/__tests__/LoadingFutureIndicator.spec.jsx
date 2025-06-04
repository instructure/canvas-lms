/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import LoadingFutureIndicator from '../index'

it('renders load more by default', () => {
  const {getByText, queryByText} = render(<LoadingFutureIndicator />)
  expect(getByText('Load more')).toBeInTheDocument()
  expect(queryByText('Loading...')).not.toBeInTheDocument()
  expect(queryByText('No more items to show')).not.toBeInTheDocument()
  expect(queryByText('Error loading more items')).not.toBeInTheDocument()
})

it('renders loading when indicated', () => {
  const {getAllByText, queryByText} = render(<LoadingFutureIndicator loadingFuture={true} />)
  expect(queryByText('Load more')).not.toBeInTheDocument()
  expect(getAllByText('Loading...')).toHaveLength(2)
})

it('renders all future items loaded regardless of other props', () => {
  const {getByText, queryByText} = render(
    <LoadingFutureIndicator loadingFuture={true} allFutureItemsLoaded={true} />,
  )
  expect(queryByText('Load more')).not.toBeInTheDocument()
  expect(queryByText('Loading...')).not.toBeInTheDocument()
  expect(getByText('No more items to show')).toBeInTheDocument()
})

it('invokes the callback when the load more button is clicked', async () => {
  const user = userEvent.setup()
  const mockLoad = jest.fn()
  const {getByText} = render(<LoadingFutureIndicator onLoadMore={mockLoad} />)
  await user.click(getByText('Load more'))
  expect(mockLoad).toHaveBeenCalledWith({loadMoreButtonClicked: true})
})

it("shows an Alert when there's a query error", () => {
  const {getByText, queryByText} = render(<LoadingFutureIndicator loadingError="uh oh" />)
  expect(getByText('Error loading more items')).toBeInTheDocument()
  expect(getByText('Load more')).toBeInTheDocument()
  expect(queryByText('Loading...')).not.toBeInTheDocument()
})
