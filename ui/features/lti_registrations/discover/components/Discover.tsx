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
import {Grid} from '@instructure/ui-grid'
import LtiFilterTray from './LtiFilterTray'
import FilterTags from './FilterTags'
import ProductCard from './ProductCard/ProductCard'
import {fetchLtiFilters, fetchProducts, fetchToolsByDisplayGroups} from '../queries/productsQuery'
import type {Product, TagGroup} from '../model/Product'
import {Heading} from '@instructure/ui-heading'
import {Pagination} from '@instructure/ui-pagination'
import useDebouncedSearch from './useDebouncedSearch'
import useDiscoverQueryParams from './useDiscoverQueryParams'
import {uniqueId} from 'lodash'
import {breakpoints} from './breakpoints'
import {useMedia} from 'react-use'
import {useAppendBreadcrumbsToDefaults} from '@canvas/breadcrumbs/useAppendBreadcrumbsToDefaults'
import {ZAccountId} from '../../manage/model/AccountId'
import Disclaimer from './common/Disclaimer'

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
  const {searchValue, handleSearchInputChange} = useDebouncedSearch({
    initialValue: queryParams.search,
    delay: 300,
    updateQueryParams,
  })
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

  const {data: displayGroupsData, isLoading: isLoadingDisplayGroups} = useQuery({
    queryKey: ['lti_tool_display_groups'],
    queryFn: () => fetchToolsByDisplayGroups(),
    enabled: !isFilterApplied,
  })

  const {data: filterData} = useQuery({
    queryKey: ['lti_filters'],
    queryFn: () => fetchLtiFilters(),
  })

  const isLarge = useMedia(`(min-width: ${breakpoints.large})`)
  const isMobile = useMedia(`(max-width: ${breakpoints.mobile})`)

  const renderProducts = (products: Product[]) => {
    if (!isLarge) {
      return (
        <Flex gap="medium" wrap="wrap" alignItems="stretch">
          {products.map((product: Product) => (
            <Flex.Item key={product.id} width="100%">
              <ProductCard product={product} />
            </Flex.Item>
          ))}
        </Flex>
      )
    }

    // Group products into chunks of 3
    const productChunks = products.reduce((resultArray, item, index) => {
      const chunkIndex = Math.floor(index / 3)

      if (!resultArray[chunkIndex]) {
        resultArray[chunkIndex] = [] // start a new chunk
      }

      resultArray[chunkIndex].push(item)
      return resultArray
    }, [] as Product[][])

    return (
      <Grid vAlign="stretch">
        {productChunks.map(chunk => (
          <Grid.Row key={chunk[0].id}>
            {chunk.map((product: Product) => (
              <Grid.Col key={product.id}>
                <ProductCard product={product} />
              </Grid.Col>
            ))}
            {/* Calculate and render empty Grid.Col components if needed */}
            {Array(3 - chunk.length)
              .fill(null)
              .map(_ => (
                <Grid.Col key={uniqueId('empty')} />
              ))}
          </Grid.Row>
        ))}
      </Grid>
    )
  }

  const setTag = (tag: TagGroup) => {
    setQueryParams({
      filters: {tags: [tag]},
    })
  }

  return (
    <div>
      <Flex gap="small" margin="0 0 small 0" direction={isMobile ? 'column-reverse' : 'row'}>
        <Flex.Item shouldGrow={true}>
          <View as="div">
            <TextInput
              renderLabel={
                <ScreenReaderContent>{I18n.t('Search by app or company name')}</ScreenReaderContent>
              }
              placeholder="Search by app or company name"
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
          numberOfResults={meta.total_count}
          queryParams={queryParams}
          updateQueryParams={updateQueryParams}
        />
      )}

      {(isFilterApplied && isLoading) || (!isFilterApplied && isLoadingDisplayGroups) ? (
        <Spinner />
      ) : isFilterApplied ? (
        <>
          {renderProducts(tools)}
          <Pagination
            as="nav"
            margin="small"
            variant="compact"
            labelNext={I18n.t('Next Page')}
            labelPrev={I18n.t('Previous Page')}
          >
            {Array.from(Array(meta.num_pages)).map((_, i) => (
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
            <div key={group.tag_group.id}>
              <Heading level="h3" as="h2" margin="large 0 0 0">
                {group.tag_group.name}
              </Heading>
              <Flex justifyItems="space-between">
                <View margin="x-small 0 small 0" padding="0 small 0 0">
                  {group.tag_group.description}
                </View>
                <CondensedButton onClick={() => setTag(group.tag_group)}>
                  {I18n.t('See All')}
                </CondensedButton>
              </Flex>
              {renderProducts(group.tools.slice(0, 3))}
            </div>
          )
        })
      )}

      <div>
        <Disclaimer />
      </div>
      {filterData && (
        <LtiFilterTray
          isTrayOpen={isTrayOpen}
          setIsTrayOpen={setIsTrayOpen}
          filterValues={filterData}
          queryParams={queryParams}
          setQueryParams={setQueryParams}
        />
      )}
    </div>
  )
}
