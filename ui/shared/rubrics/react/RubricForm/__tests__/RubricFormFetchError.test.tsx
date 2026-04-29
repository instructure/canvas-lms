/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {RubricForm, type RubricFormComponentProp} from '../index'
import * as RubricFormQueries from '../queries/RubricFormQueries'

vi.mock('../queries/RubricFormQueries', async importOriginal => {
  const actual = await importOriginal<typeof import('../queries/RubricFormQueries')>()
  return {
    ...actual,
    fetchRubric: vi.fn(),
  }
})

const ROOT_OUTCOME_GROUP = {
  id: '1',
  title: 'Root Outcome Group',
  vendor_guid: '12345',
  subgroups_url: 'https://example.com/subgroups',
  outcomes_url: 'https://example.com/outcomes',
  can_edit: true,
  import_url: 'https://example.com/import',
  context_id: '1',
  context_type: 'Account',
  description: 'Root Outcome Group Description',
  url: 'https://example.com/root',
}

describe('RubricForm Fetch Error Tests', () => {
  let queryClient: QueryClient

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })
    window.ENV = {
      ...window.ENV,
      context_asset_string: 'user_1',
    }
  })

  afterEach(() => {
    vi.resetAllMocks()
    queryClient.clear()
  })

  const renderComponent = (props?: Partial<RubricFormComponentProp>) => {
    return render(
      <QueryClientProvider client={queryClient}>
        <RubricForm
          rubricId="1"
          accountId="1"
          rootOutcomeGroup={ROOT_OUTCOME_GROUP}
          criterionUseRangeEnabled={false}
          canManageRubrics={true}
          onCancel={() => {}}
          onSaveRubric={() => {}}
          aiRubricsEnabled={false}
          {...props}
        />
      </QueryClientProvider>,
    )
  }

  describe('when fetching rubric fails', () => {
    it('displays RubricGenericErrorPage when query returns an error', async () => {
      const mockFetchRubric = vi.mocked(RubricFormQueries.fetchRubric)
      mockFetchRubric.mockRejectedValueOnce(new Error('Network error'))

      renderComponent()

      expect(await screen.findByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('displays RubricGenericErrorPage when server returns 500 error', async () => {
      const mockFetchRubric = vi.mocked(RubricFormQueries.fetchRubric)
      mockFetchRubric.mockRejectedValueOnce(new Error('Internal Server Error'))

      renderComponent()

      expect(await screen.findByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('when rubric is not found', () => {
    it('displays NotFoundArtwork when query succeeds but returns null', async () => {
      const mockFetchRubric = vi.mocked(RubricFormQueries.fetchRubric)
      mockFetchRubric.mockImplementation(async () => null)

      renderComponent()

      expect(await screen.findByText(/Whoops... Looks like nothing is here!/i)).toBeInTheDocument()
      expect(screen.getByText(/We couldn't find that page!/i)).toBeInTheDocument()
    })
  })

  describe('loading state', () => {
    it('displays LoadingIndicator while fetching rubric', () => {
      const mockFetchRubric = vi.mocked(RubricFormQueries.fetchRubric)
      mockFetchRubric.mockImplementation(
        () => new Promise(() => {}), // Never resolves
      )

      renderComponent()

      expect(screen.getByTitle('Loading')).toBeInTheDocument()
    })
  })

  describe('when rubricId is not provided', () => {
    it('does not display error or loading states for new rubric creation', () => {
      renderComponent({rubricId: undefined})

      expect(screen.getByText('Create New Rubric')).toBeInTheDocument()
      expect(screen.queryByTitle('Loading')).not.toBeInTheDocument()
      expect(screen.queryByText('Sorry, Something Broke')).not.toBeInTheDocument()
      expect(screen.queryByText(/Whoops... Looks like nothing is here!/i)).not.toBeInTheDocument()
    })
  })
})
