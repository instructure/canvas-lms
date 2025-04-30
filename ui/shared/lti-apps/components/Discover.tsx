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

import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {Alert} from '@instructure/ui-alerts'
import {useQuery, QueryFunction} from '@tanstack/react-query'
import {useMemo, useState} from 'react'
import useCreateScreenReaderFilterMessage from '../hooks/useCreateScreenReaderFilterMessage'
import useDiscoverQueryParams from '../hooks/useDiscoverQueryParams'
import {fetchLtiFilters, fetchProducts, fetchToolsByDisplayGroups} from '../queries/productsQuery'
import type {DiscoverParams} from '../hooks/useDiscoverQueryParams'
import type {ProductResponse} from '../queries/productsQuery'
import FilterTags from './apps/FilterTags'
import LtiFilterTray from './apps/LtiFilterTray'
import {Products} from './apps/Products'
import {SearchAndFilter} from './apps/SearchAndFilter'
import Disclaimer from './common/Disclaimer'

type ProductsQueryKey = readonly ['lti_product_info', DiscoverParams]

const fetchProductsFromQueryKey: QueryFunction<ProductResponse, ProductsQueryKey> = async ({
  queryKey,
}) => {
  const [, params] = queryKey
  return fetchProducts(params)
}

export const Discover = () => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const {queryParams, setQueryParams, updateQueryParams} = useDiscoverQueryParams()
  const isFilterApplied = useMemo(
    () => Object.values(queryParams.filters).flat().length > 0 || queryParams.search.length > 0,
    [queryParams],
  )

  const {
    data: {tools = [], meta = {total_count: 0, current_page: 1, num_pages: 1}} = {},
    isLoading,
  } = useQuery({
    queryKey: ['lti_product_info', queryParams] as const,
    queryFn: fetchProductsFromQueryKey,
    enabled: isFilterApplied,
  })

  const screenReaderFilterMessage = useCreateScreenReaderFilterMessage({
    queryParams,
    isFilterApplied,
    isLoading,
  })

  const {data: displayGroups, isLoading: isLoadingDisplayGroups} = useQuery({
    queryKey: ['lti_tool_display_groups'],
    queryFn: fetchToolsByDisplayGroups,
    enabled: !isFilterApplied,
  })

  const {data: filterData} = useQuery({
    queryKey: ['lti_filters'],
    queryFn: fetchLtiFilters,
  })

  return (
    <>
      <SearchAndFilter setIsTrayOpen={setIsTrayOpen} />
      {isFilterApplied && (
        <FilterTags
          numberOfResults={meta.total_count}
          queryParams={queryParams}
          updateQueryParams={updateQueryParams}
        />
      )}
      <Alert
        variant="info"
        screenReaderOnly={true}
        liveRegionPoliteness="polite"
        isLiveRegionAtomic={true}
        liveRegion={getLiveRegion}
      >
        {screenReaderFilterMessage}
      </Alert>

      <Products
        displayGroups={displayGroups || []}
        isFilterApplied={isFilterApplied}
        isLoading={isLoading}
        isLoadingDisplayGroups={isLoadingDisplayGroups}
        numberOfPages={meta.num_pages}
        tools={tools}
      />
      <Disclaimer />

      {filterData && (
        // @ts-expect-error
        <LtiFilterTray
          isTrayOpen={isTrayOpen}
          setIsTrayOpen={setIsTrayOpen}
          filterValues={filterData}
          queryParams={queryParams}
          setQueryParams={setQueryParams}
        />
      )}
    </>
  )
}
