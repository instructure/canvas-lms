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

import getCookie from '@instructure/get-cookie'
import type {Product, ToolsByDisplayGroup} from '../models/Product'
import {stringify} from 'qs'
import type {DiscoverParams} from '../hooks/useDiscoverQueryParams'
import type {LtiFilters, FilterItem} from '../models/Filter'

const accountId = window.location.pathname.split('/')[2]

type Meta = {
  count: number
  total_count: number
  current_page: number
  num_pages: number
  per_page: number
}
export type ProductResponse = {
  tools: Array<Product>
  meta: Meta
}

export const fetchProducts = async (params: DiscoverParams): Promise<ProductResponse> => {
  const {page, search} = params
  const {tags, companies, audience, versions} = params.filters

  const apiParams = {
    page,
    per_page: 21,
    q: {
      ...(search && {search_terms_cont: search}),
      ...(tags && {display_group_id_eq: tags[0]?.id}),
      ...(companies && {
        company_id_in: companies.map((company: FilterItem) => company.id),
      }),
      ...(audience && {
        audience_id_in: audience.map((audience: FilterItem) => audience.id),
      }),
      ...(versions && {
        version_id_in: versions.map((version: FilterItem) => version.id),
      }),
    },
  }

  const url = `/api/v1/accounts/${accountId}/learn_platform/products?${stringify(apiParams, {
    arrayFormat: 'brackets',
  })}`

  const response = await fetch(url, {
    method: 'get',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch products`)
  }
  const products = await response.json()

  return products || {}
}

export const fetchProductDetails = async (global_product_id: String): Promise<Product | null> => {
  if (!global_product_id) return null
  const url = `/api/v1/accounts/${accountId}/learn_platform/products/${global_product_id}`

  const response = fetch(url, {
    method: 'get',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })
    .then(resp => resp.json())
    .then(product => {
      return product
    })

  const getProduct = async () => {
    const product = await response
    return product
  }

  if (!response) {
    throw new Error(`Failed to fetch product with id ${global_product_id}`)
  }

  return getProduct()
}

export const fetchToolsByDisplayGroups = async (): Promise<ToolsByDisplayGroup> => {
  const url = `/api/v1/accounts/${accountId}/learn_platform/products_categories`

  const response = await fetch(url, {
    method: 'get',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch products categories`)
  }
  const displayGroups = await response.json()

  return displayGroups.tools_by_display_group || []
}

export const fetchLtiFilters = async (): Promise<LtiFilters> => {
  const url = `/api/v1/accounts/${accountId}/learn_platform/filters`

  const response = await fetch(url, {
    method: 'get',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch lti filters`)
  }
  const filters = await response.json()

  return filters || {}
}

export const fetchProductsByOrganization = async (
  params: DiscoverParams,
  organizationSalesforceId: string
): Promise<ProductResponse> => {
  const {page, search} = params
  const {tags, companies, audience, versions} = params.filters

  const apiParams = {
    page,
    per_page: 21,
    q: {
      ...(search && {search_terms_cont: search}),
      ...(tags && {display_group_id_eq: tags[0]?.id}),
      ...(companies && {
        company_id_in: companies.map(company => company.id),
      }),
      ...(audience && {
        audience_id_in: audience.map(audience => audience.id),
      }),
      ...(versions && {
        version_id_in: versions.map(version => version.id),
      }),
    },
  }

  const url = `/api/v1/accounts/${accountId}/learn_platform/organizations/${organizationSalesforceId}/products?${stringify(
    apiParams,
    {
      arrayFormat: 'brackets',
    }
  )}`

  const response = await fetch(url, {
    method: 'get',
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch products by organization`)
  }
  const products: ProductResponse = await response.json()
  return products
}
