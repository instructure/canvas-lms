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
import {Button, CondensedButton, IconButton} from '@instructure/ui-buttons'
import {IconEndSolid, IconFilterLine, IconSearchLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import LtiFilterTray from './LtiFilterTray'
import FilterTags from './FilterTags'
import ProductCard from './ProductCard/ProductCard'
import {fetchProducts, fetchToolsByDisplayGroups} from '../queries/productsQuery'
import type {Product} from '../model/Product'
import type {FilterItem, LtiFilter} from '../model/Filter'
import {Heading} from '@instructure/ui-heading'
import {Pagination} from '@instructure/ui-pagination'
import useDebouncedSearch from './useDebouncedSearch'
import useDiscoverQueryParams from './useDiscoverQueryParams'

// TODO: remove mock data
const filterValues: LtiFilter = {
  companies: [
    {
      id: '19a',
      name: 'Vendor Test Company',
    },
    {
      id: '9a',
      name: 'Smart Sparrow',
    },
    {
      id: '1a',
      name: 'Khan11',
    },
    {
      id: '6a',
      name: 'Test',
    },
    {
      id: '17a',
      name: 'NEW COMPANY',
    },
    {
      id: '101a',
      name: "Tom's Education Company",
    },
  ],
  versions: [
    {
      id: '9465',
      name: 'LTI v1.1',
    },
    {
      id: '9494',
      name: 'LTI v1.3',
    },
  ],
  audience: [
    {
      id: '387',
      name: 'HiEd',
    },
    {
      id: '9495',
      name: 'K-12',
    },
  ],
}

const I18n = useI18nScope('lti_registrations')

export const Discover = () => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const {queryParams, setQueryParams, updateQueryParams} = useDiscoverQueryParams()
  const {searchValue, handleSearchInputChange} = useDebouncedSearch({
    initialValue: queryParams.search,
    delay: 300,
    updateQueryParams,
  })
  const isFilterApplied = useMemo(
    () => Object.values(queryParams.filters).flat().length > 0 || queryParams.search.length > 0,
    [queryParams]
  )

  const params = () => {
    return {
      filters: queryParams.filters,
      name_cont: queryParams.search,
      page: queryParams.page,
    }
  }

  const {data, isLoading} = useQuery({
    queryKey: ['lti_product_info', queryParams],
    queryFn: () => fetchProducts(params()),
  })

  const {data: displayGroupsData, isLoading: isLoadingDisplayGroups} = useQuery({
    queryKey: ['lti_tool_display_groups'],
    queryFn: () => fetchToolsByDisplayGroups(),
  })

  const renderProducts = () => {
    return data?.tools.map((product: Product) => <ProductCard product={product} />)
  }

  const setTag = (tag: FilterItem) => {
    setQueryParams({
      filters: {tags: [tag]},
    })
  }

  return (
    <div>
      <Flex gap="small" margin="0 0 small 0">
        <Flex.Item shouldGrow={true}>
          <View as="div">
            <TextInput
              renderLabel={
                <ScreenReaderContent>
                  {I18n.t('Search by app name & company name')}
                </ScreenReaderContent>
              }
              placeholder="Search by extension name & company name"
              value={searchValue}
              onChange={handleSearchInputChange}
              renderBeforeInput={<IconSearchLine inline={false} />}
              renderAfterInput={
                queryParams.search ? (
                  <IconButton
                    size="small"
                    screenReaderLabel={I18n.t('Clear search field')}
                    withBackground={false}
                    withBorder={false}
                    onClick={() => updateQueryParams({search: ''})}
                  >
                    <IconEndSolid size="x-small" data-testid="clear-search-icon" />
                  </IconButton>
                ) : null
              }
              shouldNotWrap={true}
            />
          </View>
        </Flex.Item>
        <Button
          data-testid="apply-filters-button"
          renderIcon={IconFilterLine}
          onClick={() => setIsTrayOpen(true)}
        >
          {I18n.t('Filters')}
        </Button>
      </Flex>

      {isFilterApplied && (
        <FilterTags
          numberOfResults={data?.meta.count ?? 0}
          queryParams={queryParams}
          updateQueryParams={updateQueryParams}
        />
      )}

      {isLoading || isLoadingDisplayGroups ? (
        <Spinner />
      ) : isFilterApplied ? (
        <>
          <Flex gap="medium" wrap="wrap" alignItems="stretch">
            {renderProducts()}
          </Flex>
          <Pagination
            as="nav"
            margin="small"
            variant="compact"
            labelNext={I18n.t('Next Page')}
            labelPrev={I18n.t('Previous Page')}
          >
            {Array.from(Array(data?.meta.num_pages)).map((_, i) => (
              <Pagination.Page
                // eslint-disable-next-line react/no-array-index-key
                key={i}
                current={i === queryParams.page - 1}
                onClick={() => updateQueryParams({page: i + 1})}
              >
                {i + 1}
              </Pagination.Page>
            ))}
          </Pagination>
        </>
      ) : (
        displayGroupsData?.map(group => {
          return (
            <div key={group.tag.id}>
              <Heading level="h3" as="h2" margin="medium 0 0 0">
                {group.display_name}
              </Heading>
              <Flex justifyItems="space-between">
                <p>{group.description}</p>
                <CondensedButton onClick={() => setTag(group.tag)}>
                  {I18n.t('See All')}
                </CondensedButton>
              </Flex>
              <Flex gap="medium" wrap="wrap" alignItems="stretch">
                {group.tools.map(product => (
                  <ProductCard key={product.id} product={product} />
                ))}
              </Flex>
            </div>
          )
        })
      )}
      <LtiFilterTray
        isTrayOpen={isTrayOpen}
        setIsTrayOpen={setIsTrayOpen}
        filterValues={filterValues}
        queryParams={queryParams}
        setQueryParams={setQueryParams}
      />
    </div>
  )
}
