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

import React from 'react'
import type {Product, TagGroup, ToolsByDisplayGroup} from '../../models/Product'
import {Flex} from '@instructure/ui-flex'
import ProductCard from './ProductCard'
import {Grid} from '@instructure/ui-grid'
import {uniqueId} from 'lodash'
import {Spinner} from '@instructure/ui-spinner'
import {Pagination} from '@instructure/ui-pagination'
import useDiscoverQueryParams from '../../hooks/useDiscoverQueryParams'
import useBreakpoints from '../../hooks/useBreakpoints'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {CondensedButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_registrations')

export const Products = (props: {
  isFilterApplied: boolean
  isLoading: boolean
  isLoadingDisplayGroups?: boolean
  tools: Product[]
  displayGroups?: ToolsByDisplayGroup
  numberOfPages: number
  isOrgTools?: boolean
}) => {
  const {
    isFilterApplied,
    isLoading,
    isLoadingDisplayGroups,
    tools,
    displayGroups,
    numberOfPages,
    isOrgTools,
  } = props
  const {queryParams, setQueryParams, updateQueryParams} = useDiscoverQueryParams()
  const {isDesktop, isMobile} = useBreakpoints()

  const renderProducts = (products: Product[]) => {
    if (!isDesktop) {
      return (
        <Flex gap="mediumSmall" wrap="wrap" alignItems="stretch">
          {products.map((product: Product) => (
            <Flex.Item key={product.id} width="100%">
              <ProductCard product={product} />
            </Flex.Item>
          ))}
        </Flex>
      )
    }

    // Group products into chunks of rowLength
    const rowLength = isOrgTools ? 2 : 3
    const productChunks = products.reduce((resultArray, item, index) => {
      const chunkIndex = Math.floor(index / rowLength)

      if (!resultArray[chunkIndex]) {
        resultArray[chunkIndex] = [] // start a new chunk
      }

      resultArray[chunkIndex].push(item)
      return resultArray
    }, [] as Product[][])

    return (
      <Grid colSpacing="small" rowSpacing="small">
        {productChunks.map(chunk => (
          <Grid.Row key={chunk[0].id}>
            {chunk.map((product: Product) => (
              <Grid.Col key={product.id}>
                <ProductCard product={product} />
              </Grid.Col>
            ))}
            {/* Calculate and render empty Grid.Col components if needed */}
            {Array(rowLength - chunk.length)
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
    <>
      {(isFilterApplied && isLoading) || (!isFilterApplied && isLoadingDisplayGroups) ? (
        <Flex justifyItems="center">
          <Spinner renderTitle={I18n.t('Loading apps')} margin="xx-large" />
        </Flex>
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
            {Array.from(Array(numberOfPages)).map((_, i) => (
              <Pagination.Page
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
        displayGroups?.map(group => {
          return (
            <div key={group.tag_group.id}>
              <Heading level="h3" as="h2" margin="large 0 0 0">
                {group.tag_group.name}
              </Heading>
              <Flex justifyItems="space-between" margin="0 0 medium 0">
                <View margin="x-small 0 small 0" padding="0 small 0 0" maxWidth="70%">
                  {group.tag_group.description}
                </View>
                <CondensedButton
                  onClick={() => setTag(group.tag_group)}
                  margin={isMobile ? '0 small 0 0' : '0'}
                  aria-label={`See all ${group.tag_group.name}`}
                >
                  {I18n.t('See All')}
                </CondensedButton>
              </Flex>
              {renderProducts(group.tools.slice(0, 3))}
            </div>
          )
        })
      )}
    </>
  )
}
