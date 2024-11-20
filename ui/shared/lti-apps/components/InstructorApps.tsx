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

import React, {useMemo, useState} from 'react'
import {useQuery} from '@tanstack/react-query'
import FilterTags from './apps/FilterTags'
import LtiFilterTray from './apps/LtiFilterTray'
import {Products} from './apps/Products'
import {SearchAndFilter} from './apps/SearchAndFilter'
import Disclaimer from './common/Disclaimer'
import {
  fetchCustomFilters,
  fetchLtiFilters,
  fetchProductsByOrganization,
} from '../queries/productsQuery'
import useDiscoverQueryParams from '../hooks/useDiscoverQueryParams'
import {Header} from './apps/Header'
import type {Product} from '../models/Product'
import {View} from '@instructure/ui-view'
import useBreakpoints from '../hooks/useBreakpoints'

export const InstructorApps = () => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const {queryParams, setQueryParams, updateQueryParams} = useDiscoverQueryParams()
  const isFilterApplied = useMemo(
    () => Object.values(queryParams.filters).flat().length > 0 || queryParams.search.length > 0,
    [queryParams]
  )
  const {isDesktop} = useBreakpoints()

  const {
    data: {tools, meta, description},
    isLoading,
  } = useQuery({
    queryKey: ['lti_product_info', queryParams],
    queryFn: () => fetchProductsByOrganization(queryParams, ENV.DOMAIN_ROOT_ACCOUNT_SFID),
    initialData: {
      tools: [] as Product[],
      meta: {total_count: 0, current_page: 1, num_pages: 1, count: 0, per_page: 21},
      description: '',
    },
  })

  const {data: filterData} = useQuery({
    queryKey: ['lti_filters'],
    queryFn: () => fetchLtiFilters(),
  })

  const {data: customFilterData} = useQuery({
    queryKey: ['custom_filters'],
    queryFn: () => fetchCustomFilters(window.ENV.DOMAIN_ROOT_ACCOUNT_SFID),
  })

  return (
    <View as="div" padding={isDesktop ? 'none mediumSmall' : 'none'}>
      <Header description={description} />
      <SearchAndFilter setIsTrayOpen={setIsTrayOpen} />
      {isFilterApplied && (
        <FilterTags
          numberOfResults={meta.total_count}
          queryParams={queryParams}
          updateQueryParams={updateQueryParams}
        />
      )}

      <Products
        isFilterApplied={true}
        isLoading={isLoading}
        numberOfPages={meta.num_pages}
        tools={tools}
        isOrgTools={true}
      />
      <Disclaimer />

      {filterData && (
        <LtiFilterTray
          isTrayOpen={isTrayOpen}
          setIsTrayOpen={setIsTrayOpen}
          filterValues={{
            ...filterData,
            'approval status': customFilterData?.approval_status || [],
            'privacy status': customFilterData?.privacy_status || [],
          }}
          lpFilterValues={customFilterData?.organization_filters || []}
          queryParams={queryParams}
          setQueryParams={setQueryParams}
        />
      )}
    </View>
  )
}
