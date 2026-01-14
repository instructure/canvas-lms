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

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {UsageRightsContainer} from '../UsageRightsContainer'

vi.mock('../../../components/DiscussionOptions/UsageRights', () => ({
  UsageRights: vi.fn(({initialUsageRights, errorState, creativeCommonsOptions}) =>
    React.createElement('div', {'data-testid': 'usage-rights-mock'}, [
      React.createElement('div', {'data-testid': 'cc-options-length', key: '1'}, creativeCommonsOptions.length),
      React.createElement('div', {'data-testid': 'error-state', key: '2'}, errorState.toString()),
      React.createElement('div', {'data-testid': 'initial-rights', key: '3'}, JSON.stringify(initialUsageRights)),
    ])
  ),
}))

const mockAlertContext = {
  setOnFailure: vi.fn(),
  setOnSuccess: vi.fn(),
}

const renderWithContext = (props = {}) => {
  const defaultProps = {
    contextType: 'course',
    contextId: '123',
    onSaveUsageRights: vi.fn(),
    ...props,
  }

  return render(
    <AlertManagerContext.Provider value={mockAlertContext}>
      <UsageRightsContainer {...defaultProps} />
    </AlertManagerContext.Provider>,
  )
}

const server = setupServer(
  http.get('/api/v1/courses/:id/content_licenses', () => {
    return HttpResponse.json([
      {id: 'cc_by', name: 'CC Attribution'},
      {id: 'cc_by_sa', name: 'CC Attribution Share Alike'},
      {id: 'non_cc_license', name: 'Not a CC License'},
    ])
  }),
  http.get('/api/v1/accounts/:id/content_licenses', () => {
    return HttpResponse.json([
      {id: 'cc_by', name: 'CC Attribution'},
      {id: 'cc_by_sa', name: 'CC Attribution Share Alike'},
      {id: 'non_cc_license', name: 'Not a CC License'},
    ])
  }),
  http.get('/api/v1/groups/:id/content_licenses', () => {
    return HttpResponse.json([
      {id: 'cc_by', name: 'CC Attribution'},
      {id: 'cc_by_sa', name: 'CC Attribution Share Alike'},
      {id: 'non_cc_license', name: 'Not a CC License'},
    ])
  }),
)

describe('UsageRightsContainer', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders with default props', () => {
    const {getByTestId} = renderWithContext()
    expect(getByTestId('usage-rights-mock')).toBeInTheDocument()
  })

  it('uses default values for optional props', () => {
    const {getByTestId} = renderWithContext()

    expect(getByTestId('error-state')).toHaveTextContent('false')
  })

  it('fetches creative commons options on mount', async () => {
    const {getByTestId} = renderWithContext({
      contextType: 'course',
      contextId: '123',
    })

    await waitFor(() => {
      expect(getByTestId('cc-options-length')).toHaveTextContent('2')
    })
  })

  it('pluralizes context type correctly', async () => {
    const {getByTestId} = renderWithContext({
      contextType: 'account',
      contextId: '456',
    })

    await waitFor(() => {
      expect(getByTestId('cc-options-length')).toHaveTextContent('2')
    })
  })

  it('handles context type that already ends with s', async () => {
    const {getByTestId} = renderWithContext({
      contextType: 'groups',
      contextId: '789',
    })

    await waitFor(() => {
      expect(getByTestId('cc-options-length')).toHaveTextContent('2')
    })
  })

  it('filters creative commons options to only include CC licenses', async () => {
    const {getByTestId} = renderWithContext()

    await waitFor(() => {
      expect(getByTestId('cc-options-length')).toHaveTextContent('2')
    })
  })

  it('passes creative commons options to UsageRights component', async () => {
    server.use(
      http.get('/api/v1/courses/:id/content_licenses', () => {
        return HttpResponse.json([
          {id: 'cc_by', name: 'CC Attribution'},
          {id: 'cc_by_nc', name: 'CC Attribution Non-Commercial'},
        ])
      }),
    )

    const {getByTestId} = renderWithContext()

    await waitFor(() => {
      expect(getByTestId('cc-options-length')).toHaveTextContent('2')
    })
  })

  it('handles fetch error gracefully', async () => {
    server.use(
      http.get('/api/v1/courses/:id/content_licenses', () => {
        return HttpResponse.error()
      }),
    )

    renderWithContext()

    await waitFor(() => {
      expect(mockAlertContext.setOnFailure).toHaveBeenCalled()
    })
  })

  it('passes initialUsageRights to UsageRights component', () => {
    const initialUsageRights = {
      legalCopyright: 'Test Copyright',
      license: 'cc_by',
      useJustification: 'own_copyright',
    }

    const {getByTestId} = renderWithContext({initialUsageRights})

    expect(getByTestId('initial-rights')).toHaveTextContent(JSON.stringify(initialUsageRights))
  })

  it('passes errorState to UsageRights component', () => {
    const {getByTestId} = renderWithContext({errorState: true})

    expect(getByTestId('error-state')).toHaveTextContent('true')
  })

  it('passes onSaveUsageRights callback to UsageRights component', () => {
    const mockSave = vi.fn()
    const {getByTestId} = renderWithContext({onSaveUsageRights: mockSave})

    expect(getByTestId('usage-rights-mock')).toBeInTheDocument()
  })

  it('does not fetch creative commons options multiple times', async () => {
    const {rerender, getByTestId} = renderWithContext()

    await waitFor(() => {
      expect(getByTestId('cc-options-length')).toHaveTextContent('2')
    })

    rerender(
      <AlertManagerContext.Provider value={mockAlertContext}>
        <UsageRightsContainer contextType="course" contextId="123" onSaveUsageRights={vi.fn()} />
      </AlertManagerContext.Provider>,
    )

    expect(getByTestId('cc-options-length')).toHaveTextContent('2')
  })

  it('handles non-JSON response gracefully', async () => {
    server.use(
      http.get('/api/v1/courses/:id/content_licenses', () => {
        return new Response('invalid json', {status: 200})
      }),
    )

    renderWithContext()

    await waitFor(() => {
      expect(mockAlertContext.setOnFailure).toHaveBeenCalled()
    })
  })
})
