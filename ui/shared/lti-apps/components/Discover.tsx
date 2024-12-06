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
import {useScope as useI18nScope} from '@canvas/i18n'
import LtiFilterTray from './apps/LtiFilterTray'
import FilterTags from './apps/FilterTags'
import {fetchLtiFilters, fetchProducts, fetchToolsByDisplayGroups} from '../queries/productsQuery'
import useDiscoverQueryParams from '../hooks/useDiscoverQueryParams'
import {useAppendBreadcrumbsToDefaults} from '@canvas/breadcrumbs/useAppendBreadcrumbsToDefaults'
import {ZAccountId} from '../models/AccountId'
import Disclaimer from './common/Disclaimer'
import {Products} from './apps/Products'
import {SearchAndFilter} from './apps/SearchAndFilter'

const I18n = useI18nScope('lti_registrations')

export const Discover = () => {
  const accountId = ZAccountId.parse(window.location.pathname.split('/')[2])
  useAppendBreadcrumbsToDefaults(
    [
      {
        name: I18n.t('Discover'),
        url: `/accounts/${accountId}/apps`,
      },
    ],
    !!window.ENV.FEATURES.lti_registrations_next
  )

  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const {queryParams, setQueryParams, updateQueryParams} = useDiscoverQueryParams()
  const isFilterApplied = useMemo(
    () => Object.values(queryParams.filters).flat().length > 0 || queryParams.search.length > 0,
    [queryParams]
  )

  const {
    data: {tools = [], meta = {total_count: 0, current_page: 1, num_pages: 1}} = {},
    isLoading,
  } = useQuery({
    queryKey: ['lti_product_info', queryParams],
    queryFn: () => fetchProducts(queryParams),
    enabled: isFilterApplied,
  })

  const {data: displayGroups, isLoading: isLoadingDisplayGroups} = useQuery({
    queryKey: ['lti_tool_display_groups'],
    queryFn: () => fetchToolsByDisplayGroups(),
    enabled: !isFilterApplied,
  })

  const {data: filterData} = useQuery({
    queryKey: ['lti_filters'],
    queryFn: () => fetchLtiFilters(),
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
