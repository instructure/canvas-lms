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

import React from 'react'
import {renderHook} from '@testing-library/react-hooks/dom'
import {waitFor} from '@testing-library/react'
import useProduct from '../useProduct'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import type {Product} from '../../models/Product'

describe('isError, isLoading, and product return as expected', () => {
  let mockedData: Product
  beforeEach(() => {
    mockedData = {
      id: '123',
      global_product_id: '321',
      name: 'Product Name',
      company: {id: 1, name: 'Company Name', company_url: 'http://company.com'},
      logo_url: 'http://company.com/logo.png',
      tagline: 'Product Tagline',
      description: 'Product Description',
      updated_at: '2021-01-01',
      tool_integration_configurations: {
        lti_13: [
          {id: 1, integration_type: 'lti13', url: 'http://lti13.com', unified_tool_id: 'lti13'},
        ],
      },
      lti_configurations: {
        lti_13: {services: ['service1'], placements: ['placement1']},
      },
      badges: [{name: 'badge1', image_url: 'http://badge1.com', link: 'http://badge1.com'}],
      screenshots: ['http://screenshot1.com'],
      terms_of_service_url: 'http://tos.com',
      privacy_policy_url: 'http://privacy.com',
      accessibility_url: 'http://accessibility.com',
      support_link: 'http://support.com',
      tags: [{id: '4', name: 'tag1'}],
      integration_resources: {
        comments: null,
        resources: [],
      },
    }

    global.fetch = jest.fn().mockResolvedValue({
      // in the productsQuery.ts file, the fetchResponse function checks for response.ok to see if the fetch was successful
      // so we need to mock the response.ok property to be true otherwise the function will throw an error
      // TODO: a better solution when we write negative tests
      ok: true,
      json: jest.fn().mockResolvedValue(mockedData),
    })
  })

  it("Doesn't return an error when provided with productId", () => {
    const productId = '456'
    const queryClient = new QueryClient()
    const {result} = renderHook(() => useProduct({productId}), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    expect(result.current.isError).toEqual(false)
  })

  it('Returns isLoading while product is undefined/promise is being resolved', () => {
    const productId = '789'
    const queryClient = new QueryClient()
    const {result} = renderHook(() => useProduct({productId}), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    expect(result.current.isLoading).toEqual(true)
  })

  it('Promise resolves successfully', async () => {
    const productId = '123'
    const queryClient = new QueryClient()
    const {result} = renderHook(() => useProduct({productId}), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })
    expect(result.current.isLoading).toEqual(true)
    await waitFor(() => expect(result.current.product).toBe(mockedData))
    expect(result.current.isLoading).toEqual(false)
    expect(result.current.isError).toEqual(false)
  })
})
