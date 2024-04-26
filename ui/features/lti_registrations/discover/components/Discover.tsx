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

import React, {useEffect, useMemo, useState} from 'react'
import {useSearchParams} from 'react-router-dom'
import {useQuery} from '@tanstack/react-query'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconEndSolid, IconFilterLine, IconSearchLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import LtiFilterTray from './LtiFilterTray'
import FilterTags from './FilterTags'
import ProductCard from './ProductCard'
import {fetchProducts} from '../queries/productsQuery'
import type {Product} from '../model/Product'
import type {FilterItem, LtiFilter} from '../model/Filter'

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
  const [searchParams, setSearchParams] = useSearchParams()
  const [filters, setFilters] = useState<LtiFilter>({companies: [], versions: [], audience: []})
  const searchString = useMemo(() => searchParams.get('search') ?? '', [searchParams])

  const params = () => {
    return {
      filters,
      name_cont: searchString,
    }
  }

  const {data, isLoading} = useQuery({
    queryKey: ['lti_product_info', filters, searchString],
    queryFn: () => fetchProducts(params()),
  })

  useEffect(() => {
    const queryParams = searchParams.get('filter')
    const params = queryParams
      ? JSON.parse(queryParams)
      : {companies: [], versions: [], audience: []}
    setFilters(params as unknown as LtiFilter)
  }, [searchParams])

  const renderProducts = () => {
    return data?.tools.map((product: Product) => <ProductCard product={product} />)
  }

  return (
    <div>
      <Flex gap="small" margin="0 0 small 0">
        <Flex.Item shouldGrow={true}>
          <View as="div">
            <TextInput
              renderLabel={
                <ScreenReaderContent>
                  {I18n.t('Search by extension name & company name')}
                </ScreenReaderContent>
              }
              placeholder="Search by extension name & company name"
              value={searchString}
              onChange={event =>
                setSearchParams({
                  filter: searchParams.get('filter') ?? [],
                  search: event.target.value,
                })
              }
              renderBeforeInput={<IconSearchLine inline={false} />}
              renderAfterInput={
                searchString ? (
                  <IconButton
                    size="small"
                    screenReaderLabel={I18n.t('Clear search field')}
                    withBackground={false}
                    withBorder={false}
                    onClick={() =>
                      setSearchParams({filter: searchParams.get('filter') ?? [], search: ''})
                    }
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
      {searchString && (
        <p>
          {data?.meta.count ?? 0} {I18n.t('results for')} &quot;{searchString}&quot;
        </p>
      )}

      <FilterTags numberOfResults={data?.meta.count ?? 0} />

      <Flex gap="medium" wrap="wrap">
        {isLoading ? <Spinner /> : renderProducts()}
      </Flex>

      <LtiFilterTray
        isTrayOpen={isTrayOpen}
        setIsTrayOpen={setIsTrayOpen}
        filterValues={filterValues}
      />
    </div>
  )
}
