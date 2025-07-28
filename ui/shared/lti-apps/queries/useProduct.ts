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
import {fetchProductDetails} from './productsQuery'
import type {UseQueryOptions, QueryFunction} from '@tanstack/react-query'
import type {Product} from '../models/Product'
import {useQuery} from '@tanstack/react-query'

type ProductQueryKey = readonly [string, string]

export type UseProductProps = {
  productId: string
  queryOptions?: Partial<UseQueryOptions<Product | null, Error, Product | null, ProductQueryKey>>
}

const queryFn = ({
  queryKey,
}: {
  queryKey: ProductQueryKey
}) => {
  const [, productId] = queryKey
  return fetchProductDetails(productId)
}

const useProduct = ({productId, queryOptions = {}}: UseProductProps) => {
  const {
    data: product,
    isLoading,
    isError,
  } = useQuery<Product | null, Error, Product | null, ProductQueryKey>({
    queryKey: ['lti_product_detail', productId],
    queryFn,
    ...queryOptions,
  })

  return {product, isLoading, isError}
}

export default useProduct
