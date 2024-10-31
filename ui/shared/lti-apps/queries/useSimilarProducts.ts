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
import type {UseQueryOptions} from '@tanstack/react-query'
import type {Product} from '../models/Product'
import type {DiscoverParams} from '../hooks/useDiscoverQueryParams'
import type {ProductResponse} from './productsQuery'
import {useQuery} from '@tanstack/react-query'

export type UseSimilarProductsProps = {
  params: Partial<DiscoverParams>
  product: Product
  queryOptions?: Partial<UseQueryOptions>
}

const useSimilarProducts = ({params, product, queryOptions = {}}: UseSimilarProductsProps) => {
  const {data: otherProductsByCompany} = useQuery({
    queryKey: ['lti_similar_products_by_company', product?.company],
    queryFn: () =>
      fetchProducts({
        ...params,
        search: params.search ?? '',
      } as DiscoverParams),
    ...queryOptions,
  })

  return {otherProductsByCompany: otherProductsByCompany as ProductResponse}
}

export default useSimilarProducts
