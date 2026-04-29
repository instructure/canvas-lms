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
import FullBatchDropdown from '../FullBatchDropdown'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import {EnrollmentTerms, Term} from 'api'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import userEvent from '@testing-library/user-event'

const server = setupServer()

const allTerms: Term[] = [
  {
    id: '1',
    name: 'Fall',
    start_at: '',
    end_at: '',
  },
  {
    id: '2',
    name: 'Fall 2025',
    start_at: '',
    end_at: '',
  },
  {id: '3', name: 'Spring 1998', start_at: '', end_at: ''},
  {id: '4', name: 'Spring', start_at: '', end_at: ''},
]

const props = {
  onSelect: vi.fn(),
  accountId: '1',
  isVisible: true,
}

const queryClient = new QueryClient()

const renderDropdown = (overrides = {}) => {
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <FullBatchDropdown {...props} {...overrides} />
    </MockedQueryClientProvider>,
  )
}

// Store dynamic term filters that can be set per-test
const termFilters: Map<string, EnrollmentTerms> = new Map()

const mockQuery = (termName: string, terms: EnrollmentTerms) => {
  termFilters.set(termName, terms)
}

describe('FullBatchDropdown', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    termFilters.clear()
    termFilters.set('', {enrollment_terms: allTerms})

    server.use(
      http.get(`/api/v1/accounts/${props.accountId}/terms`, ({request}) => {
        const url = new URL(request.url)
        const requestedTermName = url.searchParams.get('term_name') || ''
        const terms = termFilters.get(requestedTermName)
        if (terms) {
          return HttpResponse.json(terms)
        }
        return HttpResponse.json({enrollment_terms: []})
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })

  it('renders nothing when not visible', () => {
    const {queryByTestId} = renderDropdown({...props, isVisible: false})

    expect(queryByTestId('full-batch-dropdown')).toBeNull()
    expect(queryByTestId('full-batch-warning')).toBeNull()
  })

  it('renders dropdown with options on focus and defaults to first option', async () => {
    const user = userEvent.setup()
    const {queryByTestId, getByTestId} = renderDropdown(props)

    expect(queryByTestId('option-1')).toBeNull()
    expect(queryByTestId('option-2')).toBeNull()
    const dropdown = getByTestId('full-batch-dropdown')
    await waitFor(() => {
      expect(dropdown).toHaveValue('Fall')
    })

    await user.click(dropdown)
    expect(getByTestId('option-1')).toBeInTheDocument()
    expect(getByTestId('option-2')).toBeInTheDocument()
  })

  it('fetches terms when input changes', async () => {
    mockQuery('Fall 20', {enrollment_terms: [allTerms[1]]})
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = renderDropdown(props)

    const dropdown = getByTestId('full-batch-dropdown')
    await waitFor(() => {
      expect(dropdown).toHaveValue('Fall')
    })
    dropdown.focus()

    // type '20' to filter terms
    await user.type(dropdown, ' 20')
    await waitFor(() => {
      expect(queryByTestId('option-1')).toBeNull()
      expect(getByTestId('option-2')).toBeInTheDocument()
    })
  })

  it('executes onSelect when an option is selected', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderDropdown(props)

    const dropdown = getByTestId('full-batch-dropdown')
    await user.click(dropdown)
    const option1 = getByTestId('option-1')
    await user.click(option1)

    expect(props.onSelect).toHaveBeenCalledWith('1')
  })

  it('sticks to the selected option after blurring', async () => {
    const user = userEvent.setup()
    const {getByTestId} = renderDropdown(props)

    const dropdown = getByTestId('full-batch-dropdown')
    await user.click(dropdown)
    const option1 = getByTestId('option-4')
    await user.click(option1)

    expect(props.onSelect).toHaveBeenCalledWith('4')

    dropdown.blur()
    await waitFor(() => {
      expect(dropdown).toHaveValue('Spring')
    })
  })
})
