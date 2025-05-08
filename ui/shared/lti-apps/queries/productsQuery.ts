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
import type {OrganizationProduct, Product, ToolsByDisplayGroup} from '../models/Product'
import {stringify} from 'qs'
import type {DiscoverParams} from '../hooks/useDiscoverQueryParams'
import type {LtiFilters, FilterItem, OrganizationFiltes} from '../models/Filter'

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
export type OrganizationProductResponse = {
  description: string
  tools: Array<OrganizationProduct>
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
        audience_id_in: audience.map((aud: FilterItem) => aud.id),
      }),
      ...(versions && {
        version_id_in: versions.map((version: FilterItem) => version.id),
      }),
    },
  }

  const url = `/api/v1/accounts/${accountId}/learn_platform/products?${stringify(apiParams, {
    arrayFormat: 'brackets',
  })}`

  const products = await fetchResponse('get', url, 'Failed to fetch products')

  return products || {}
}

export const fetchProductDetails = async (global_product_id: string): Promise<Product | null> => {
  if (!global_product_id) return null
  const url = `/api/v1/accounts/${accountId}/learn_platform/products/${global_product_id}`

  const product = await fetchResponse(
    'get',
    url,
    `Failed to fetch product with id ${global_product_id}`,
  )

  return product || {}
}

export const fetchToolsByDisplayGroups = async (): Promise<ToolsByDisplayGroup> => {
  const url = `/api/v1/accounts/${accountId}/learn_platform/products_categories`

  const displayGroups = await fetchResponse('get', url, 'Failed to fetch products categories')

  return displayGroups.tools_by_display_group || []
}

export const fetchLtiFilters = async (): Promise<LtiFilters> => {
  const url = `/api/v1/accounts/${accountId}/learn_platform/filters`

  const filters = await fetchResponse('get', url, 'Failed to fetch lti filters')

  return filters || {}
}

export const fetchCustomFilters = async (): Promise<OrganizationFiltes> => {
  const salesforceId = ENV.DOMAIN_ROOT_ACCOUNT_SFID
  const url = `/api/v1/accounts/${accountId}/learn_platform/custom_filters?${stringify(
    {salesforce_id: salesforceId},
    {
      arrayFormat: 'brackets',
    },
  )}`

  const filters = await fetchResponse('get', url, 'Failed to fetch custom filters')

  return filters || {}
}

export const fetchProductsByOrganization = async (
  params: DiscoverParams,
): Promise<OrganizationProductResponse> => {
  const organizationSalesforceId = ENV.DOMAIN_ROOT_ACCOUNT_SFID
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
        audience_id_in: audience.map(aud => aud.id),
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
    },
  )}`

  const products: OrganizationProductResponse = await fetchResponse(
    'get',
    url,
    'Failed to fetch products by organization',
  )

  return products
}

async function fetchResponse(method: string, url: string, errorText: string): Promise<any> {
  const response = await fetch(url, {
    method,
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'content-Type': 'application/json',
    },
  })

  const products = await response.json()

  if (!response.ok) {
    if (products.lp_server_error) {
      throw new Error(products.json.error)
    }
    throw new Error(errorText)
  }

  return products
}
