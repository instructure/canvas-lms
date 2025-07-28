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
import useSimilarProducts from '../useSimilarProducts'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import type {Product} from '../../models/Product'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

describe('Promise resolution', () => {
  let mockedData: Product
  let server: ReturnType<typeof setupServer>

  beforeAll(() => {
    server = setupServer()
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

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
      canvas_lti_configurations: [
        {
          id: 12,
          integration_type: 'lti_13_dynamic_registration',
          description: 'description',
          lti_placements: ['dr'],
          lti_services: ['gk'],
          url: 'google.com',
          unified_tool_id: '1234',
        },
      ],
      tool_integration_configurations: {
        lti_11: [],
        lti_13: [],
      },
      integration_badges: [
        {
          name: 'badge1',
          image_url: 'http://badge1.com',
          link: 'http://badge1.com',
          description: 'badge1',
        },
      ],
      screenshots: ['http://screenshot1.com'],
      terms_of_service_url: 'http://tos.com',
      privacy_policy_url: 'http://privacy.com',
      accessibility_url: 'http://accessibility.com',
      support_url: 'http://support.com',
      tags: [{id: '4', name: 'tag1'}],
      integration_resources: {
        comments: null,
        resources: [],
      },
      privacy_and_security_badges: [],
      accessibility_badges: [],
    }

    server.use(
      http.get('*/api/v1/accounts/*/learn_platform/products', () => {
        return HttpResponse.json(mockedData)
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
  })

  it('Promise resolves successfully when provided a product', async () => {
    const params = () => {
      return {
        filters: {
          companies: [{id: mockedData?.company.id.toString(), name: mockedData?.company.name}],
        },
      }
    }

    const queryClient = new QueryClient()
    const {result} = renderHook(() => useSimilarProducts({params: params(), product: mockedData}), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    })

    await waitFor(() => expect(result.current).not.toBeUndefined())
  })
})
