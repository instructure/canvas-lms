// /*
//  * Copyright (C) 2020 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */

import React from 'react'
import {render, waitFor, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import FeatureFlags from '../FeatureFlags'
import sampleData from './sampleData.json'

const rows = [
  sampleData.allowedOnFeature,
  sampleData.allowedFeature,
  sampleData.onFeature,
  sampleData.offFeature,
  sampleData.betaFeature
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
      const searchField = await findByPlaceholderText('Search')
      expect(searchField).toBeInTheDocument()
      expect(searchField.value).toBe('')
    })

    it('filters rows to show only those matching query', async () => {
      const {findByPlaceholderText, getByText, queryByText} = render(<FeatureFlags />)
      const searchField = await findByPlaceholderText('Search')
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
      const searchField = await findByPlaceholderText('Search')
      fireEvent.change(searchField, {target: {value: 'Feature 4'}})
      expect(await getAllByText('User')[0]).toBeInTheDocument()
      await waitFor(() => {
        expect(queryByText('Account')).not.toBeInTheDocument()
        expect(queryByText('Course')).not.toBeInTheDocument()
      })
    })
  })

  describe('filter', () => {
    describe('with feature disabled', () => {
      it('does not render', async () => {
        const {queryAllByPlaceholderText} = render(<FeatureFlags />)
        const filterField = await queryAllByPlaceholderText('Filter Features')
        expect(filterField.length).toBe(0)
      })
    })
    describe('with feature enabled', () => {
      beforeEach(() => {
        ENV.FEATURES = {feature_flag_filters: true}
      })

      it('renders an empty multiselect bar on load', async () => {
        const {findByPlaceholderText} = render(
          <div>
            <FeatureFlags />
            <div id="aria_alerts" role="alert" />
          </div>
        )
        const filterField = await findByPlaceholderText('Filter Features')
        expect(filterField).toBeInTheDocument()
        expect(filterField.value).toBe('')
      })

      it('filters based on tag', async () => {
        const {findByPlaceholderText, getAllByText, queryByText} = render(
          <div>
            <FeatureFlags />
            <div id="aria_alerts" role="alert" />
          </div>
        )
        const filterField = await findByPlaceholderText('Filter Features')
        fireEvent.change(filterField, {target: {value: 'active'}})
        fireEvent.click(await getAllByText('Active Development')[1])
        await waitFor(() => {
          expect(getAllByText('Course')[0]).toBeInTheDocument()
          expect(getAllByText('Beta Feature')[0]).toBeInTheDocument()
          expect(queryByText('Account')).not.toBeInTheDocument()
          expect(queryByText('User')).not.toBeInTheDocument()
        })
      })

      it('renders section titles for types', async () => {
        const {queryAllByTestId} = render(
          <div>
            <FeatureFlags />
            <div id="aria_alerts" role="alert" />
          </div>
        )
        await waitFor(() => {
          expect(queryAllByTestId('ff-table-heading')[0]).toHaveTextContent('Feature Previews')
          expect(queryAllByTestId('ff-table-heading')[1]).toHaveTextContent('Stable Features')
        })
      })

      it('hides section titles if no row exists in section after search', async () => {
        const {findByPlaceholderText, getAllByText, queryAllByTestId, queryByText} = render(
          <div>
            <FeatureFlags />
            <div id="aria_alerts" role="alert" />
          </div>
        )
        const searchField = await findByPlaceholderText('Search')
        fireEvent.change(searchField, {target: {value: 'Feature 4'}})
        expect(await getAllByText('User')[0]).toBeInTheDocument()
        await waitFor(() => {
          expect(queryAllByTestId('ff-table-heading')[0]).toHaveTextContent('Feature Previews')
          expect(queryByText('Stable Features')).not.toBeInTheDocument()
          expect(queryByText('Account')).not.toBeInTheDocument()
          expect(queryByText('Course')).not.toBeInTheDocument()
        })
      })
    })
  })
})
