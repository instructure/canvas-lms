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
import {fetchProductDetails} from '../../queries/productsQuery'
import type {UseQueryOptions} from '@tanstack/react-query'
import type {Product} from '../../model/Product'
import {useQuery} from '@tanstack/react-query'

export type UseProductProps = {
  productId: string
  queryOptions?: Partial<UseQueryOptions>
}

const useProduct = ({productId, queryOptions = {}}: UseProductProps) => {
  const {
    data: product,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ['lti_product_detail'],
    queryFn: () => fetchProductDetails(productId),
    ...queryOptions,
  })

  return {product: product as Product, isLoading, isError}
}

export default useProduct
