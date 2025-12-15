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

import {render, waitFor} from '@testing-library/react'
import OverTimeModal from '../OverTimeModal'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import {queryClient} from '@canvas/query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'

// Mock the OverTimeGraph component from its separate file
vi.mock('../OverTimeGraph', () => ({
  default: vi.fn(({name, url}) => (
    <div data-testid="over-time-graph">
      <div>Mocked Graph for {name}</div>
      <a href={url}>Download CSV</a>
    </div>
  )),
}))

const renderModal = () => {
  const screen = render(
    <div>
      <button data-key="test_type" data-name="TestType" className="over_time_link">
        View TestType
      </button>
      <button data-key="another_type" data-name="AnotherType" className="over_time_link">
        View AnotherType
      </button>
      <MockedQueryClientProvider client={queryClient}>
        <OverTimeModal accountId={'1'} />
      </MockedQueryClientProvider>
    </div>,
  )
  return screen
}

const fakeResponse = [
  [1704067200000, 5],
  [1704153600000, 10],
  [1704240000000, 15],
]

const generateUrl = (accountId: string, key: string) =>
  `/accounts/${accountId}/statistics/over_time/${key}`

describe('OverTimeModal', () => {
  afterAll(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('opens and fetches when the link is clicked', async () => {
    const initialUrl = generateUrl('1', 'test_type')
    const user = userEvent.setup()
    fetchMock.get(initialUrl, fakeResponse)
    const {getByText} = renderModal()

    expect(fetchMock.called(initialUrl)).toBe(false)
    user.click(getByText('View TestType'))

    await waitFor(() => {
      expect(fetchMock.called(initialUrl)).toBe(true)
      expect(getByText('TestType Over Time')).toBeInTheDocument()
    })
  })

  it('validates that clicking the close button will close the modal', async () => {
    const initialUrl = generateUrl('1', 'another_type')
    const user = userEvent.setup()
    fetchMock.get(initialUrl, fakeResponse)
    const {getByText, queryByText, getByTestId} = renderModal()

    await user.click(getByText('View AnotherType'))

    await waitFor(() => {
      expect(getByText('AnotherType Over Time')).toBeInTheDocument()
    })

    const closeButton = getByTestId('close-button')
    await user.click(closeButton)

    await waitFor(() => {
      expect(queryByText('AnotherType Over Time')).toBeNull()
    })
  })

  it('renders error message when fetch request fails', async () => {
    const initialUrl = generateUrl('1', 'another_type')
    const user = userEvent.setup()
    fetchMock.get(initialUrl, 500)
    const {getByText} = renderModal()

    await user.click(getByText('View AnotherType'))

    await waitFor(() => {
      expect(getByText('AnotherType Over Time')).toBeInTheDocument()
      expect(getByText('Failed to fetch graph data')).toBeInTheDocument()
    })
  })
})
