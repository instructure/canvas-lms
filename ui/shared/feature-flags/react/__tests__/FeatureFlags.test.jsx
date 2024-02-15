// @vitest-environment jsdom
/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import FeatureFlags from '../FeatureFlags'
import sampleData from './sampleData.json'

const rows = [
  sampleData.allowedOnFeature,
  sampleData.allowedFeature,
  sampleData.onFeature,
  sampleData.offFeature,
  sampleData.betaFeature,
]

describe('feature_flags::FeatureFlags', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  beforeEach(() => {
    ENV.CONTEXT_BASE_URL = '/accounts/1'
    const route = `/api/v1${ENV.CONTEXT_BASE_URL}/features?hide_inherited_enabled=true&per_page=50`
    fetchMock.getOnce(route, JSON.stringify(rows))
  })

  it('Renders all the appropriate sections', async () => {
    const {getAllByText, queryByText} = render(<FeatureFlags />)
    await waitFor(() => expect(getAllByText('Account')[0]).toBeInTheDocument())
    expect(getAllByText('Course')[0]).toBeInTheDocument()
    expect(getAllByText('User')[0]).toBeInTheDocument()
    expect(queryByText('Site Admin')).not.toBeInTheDocument()
  })

  describe('search', () => {
    it('renders an empty search bar on load', async () => {
      const {findByPlaceholderText} = render(<FeatureFlags />)
      const searchField = await findByPlaceholderText('Search by name or id')
      expect(searchField).toBeInTheDocument()
      expect(searchField.value).toBe('')
    })

    it('filters rows to show only those matching query', async () => {
      const {findByPlaceholderText, getByText, queryByText} = render(<FeatureFlags />)
      const searchField = await findByPlaceholderText('Search by name or id')
      const query = 'Feature 3'
      fireEvent.change(searchField, {target: {value: query}})
      expect(await getByText(query)).toBeInTheDocument()
      await waitFor(() => {
        expect(queryByText('Feature 1')).not.toBeInTheDocument()
        expect(queryByText('Feature 2')).not.toBeInTheDocument()
      })
    })

    it('hides section titles if no row exists in section after search', async () => {
      const {findByPlaceholderText, getAllByText, queryByText} = render(<FeatureFlags />)
      const searchField = await findByPlaceholderText('Search by name or id')
      fireEvent.change(searchField, {target: {value: 'Feature 4'}})
      expect(await getAllByText('User')[0]).toBeInTheDocument()
      await waitFor(() => {
        expect(queryByText('Account')).not.toBeInTheDocument()
        expect(queryByText('Course')).not.toBeInTheDocument()
      })
    })

    // FOO-4286
    it.skip('performs search when search input length is 3 characters or more', async () => {
      const {findByPlaceholderText, getAllByTestId, queryAllByTestId} = render(<FeatureFlags />)
      const searchField = await findByPlaceholderText('Search by name or id')
      const allFeatureFlagsCount = getAllByTestId('ff-table-row').length

      // Checks no query case and also resets the search to ensure other tests are accurate
      const checkNoQuery = async () => {
        fireEvent.change(searchField, {target: {value: ''}})
        await waitFor(() => {
          expect(getAllByTestId('ff-table-row')).toHaveLength(allFeatureFlagsCount)
        })
      }

      // Check short query case
      await checkNoQuery()
      fireEvent.change(searchField, {target: {value: 'Fe'}})
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(allFeatureFlagsCount)
      })

      // Check name-based search matching
      await checkNoQuery()
      fireEvent.change(searchField, {target: {value: 'Feature 4'}})
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(1)
      })

      // Check feature-id based search matching
      await checkNoQuery()
      fireEvent.change(searchField, {target: {value: 'feature4'}})
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(1)
      })

      // Check not found case
      await checkNoQuery()
      fireEvent.change(searchField, {target: {value: 'asdfasjdhf1234'}})
      await waitFor(() => {
        expect(queryAllByTestId('ff-table-row')).toHaveLength(0)
      })
    })

    it('displays all feature flags when user clears search input', async () => {
      const {findByPlaceholderText, getAllByTestId} = render(<FeatureFlags />)
      const searchField = await findByPlaceholderText('Search by name or id')
      const allFeatureFlagsCount = getAllByTestId('ff-table-row').length
      fireEvent.change(searchField, {target: {value: 'Feature 4'}})
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(1)
      })
      fireEvent.change(searchField, {target: {value: ''}})
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(allFeatureFlagsCount)
      })
    })
  })

  describe('filter by state', () => {
    it('should render All as default', async () => {
      const {getByLabelText, getAllByTestId} = render(<FeatureFlags />)
      await waitFor(() => {
        expect(getByLabelText('Filter by')).toBeInTheDocument()
      })
      expect(getByLabelText('Filter by').closest('input').value).toEqual('All')
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(5)
      })
    })

    it('filters rows to show enabled', async () => {
      const {getByText, getAllByTestId, getByLabelText} = render(<FeatureFlags />)
      await waitFor(() => {
        expect(getByLabelText('Filter by')).toBeInTheDocument()
      })
      fireEvent.click(getByLabelText('Filter by'))
      fireEvent.click(getByText('Enabled'))
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(3)
      })
    })

    it('filters rows to show disabled', async () => {
      const {getByText, getAllByTestId, getByLabelText} = render(<FeatureFlags />)
      await waitFor(() => {
        expect(getByLabelText('Filter by')).toBeInTheDocument()
      })
      fireEvent.click(getByLabelText('Filter by'))
      fireEvent.click(getByText('Disabled'))
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(2)
      })
    })
  })

  it('filters when search and state filter are used', async () => {
    const {getByText, getAllByTestId, getByLabelText, findByPlaceholderText} = render(
      <FeatureFlags />
    )
    await waitFor(() => {
      expect(getByLabelText('Filter by')).toBeInTheDocument()
    })
    fireEvent.click(getByLabelText('Filter by'))
    fireEvent.click(getByText('Disabled'))
    const searchField = await findByPlaceholderText('Search by name or id')
    fireEvent.change(searchField, {target: {value: 'Feature 1'}})
    await waitFor(() => {
      expect(getAllByTestId('ff-table-row')).toHaveLength(1)
    })
    fireEvent.change(searchField, {target: {value: 'Feature 4'}})
    await waitFor(() => {
      expect(getAllByTestId('ff-table-row')).toHaveLength(1)
    })
  })

  describe('clear', () => {
    it('clears search input & resets state filter to all', async () => {
      const {getByLabelText, getByText, findByPlaceholderText, getAllByTestId} = render(
        <FeatureFlags />
      )
      await waitFor(() => {
        expect(getByLabelText('Filter by')).toBeInTheDocument()
      })
      const allFeatureFlagsCount = getAllByTestId('ff-table-row').length
      fireEvent.click(getByLabelText('Filter by'))
      fireEvent.click(getByText('Disabled'))
      const searchField = await findByPlaceholderText('Search by name or id')
      fireEvent.change(searchField, {target: {value: 'Feature 1'}})
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(1)
      })
      fireEvent.click(getByText('Clear'))
      await waitFor(() => {
        expect(getAllByTestId('ff-table-row')).toHaveLength(allFeatureFlagsCount)
      })
    })
  })
})
