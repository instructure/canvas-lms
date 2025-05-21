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

import {fetchProducts} from './productsQuery'
import type {Product} from '../models/Product'
import type {DiscoverParams} from '../hooks/useDiscoverQueryParams'
import {useQuery} from '@tanstack/react-query'
import {useCallback} from 'react'

const fetchSimilarProductsByCompany = (params: Partial<DiscoverParams>) => {
  return fetchProducts({
    ...params,
    search: params.search ?? '',
  } as DiscoverParams)
}

export type UseSimilarProductsProps = {
  params: Partial<DiscoverParams>
  product?: Product | null
}

const useSimilarProducts = ({params, product}: UseSimilarProductsProps) => {
  const queryFn = useCallback(() => {
    return fetchSimilarProductsByCompany(params)
  }, [params])

  const {data} = useQuery({
    enabled: !!params?.filters?.companies?.[0]?.id,
    queryKey: ['lti_similar_products_by_company', product?.company],
    queryFn,
  })

  return {otherProductsByCompany: data}
}

export default useSimilarProducts
