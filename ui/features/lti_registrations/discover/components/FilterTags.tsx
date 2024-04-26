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

import React, {useState, useEffect, useMemo} from 'react'
import type {FilterItem, LtiFilter} from '../model/Filter'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {useSearchParams} from 'react-router-dom'
import {Heading} from '@instructure/ui-heading'

const I18n = useI18nScope('lti_registrations')

export default function FilterTags(props: {numberOfResults: number}) {
  const [searchParams, setSearchParams] = useSearchParams()
  const [filters, setFilters] = useState<LtiFilter>({companies: [], versions: [], audience: []})
  const isAnyFilter = useMemo(() => {
    return Object.values(filters).flat().length > 0
  }, [filters])

  useEffect(() => {
    const queryParams = searchParams.get('filter')
    const params = queryParams
      ? JSON.parse(queryParams)
      : {companies: [], versions: [], audience: []}
    setFilters(params as unknown as LtiFilter)
  }, [searchParams])

  const removeFilter = (filter: FilterItem) => {
    const newFilters = Object.fromEntries(
      Object.entries(filters).map(([key, value]) => [key, value.filter(f => f.id !== filter.id)])
    )
    setSearchParams({
      search: searchParams.get('search') ?? '',
      filter: JSON.stringify(newFilters),
    })
  }

  return (
    <>
      {isAnyFilter && (
        <>
          <Heading level="h2">{I18n.t('Search Results')}</Heading>
          <Flex gap="x-small" wrap="no-wrap" margin="0 0 medium 0">
            <p>
              {props.numberOfResults} {I18n.t('result(s) filtered by')}
            </p>
            {Object.values(filters)
              .flat()
              .map(filter => {
                return (
                  <Flex.Item padding="0 small 0 0" key={filter.id}>
                    <Tag
                      text={filter.name}
                      dismissible={true}
                      onClick={() => removeFilter(filter)}
                    />
                  </Flex.Item>
                )
              })}
          </Flex>
        </>
      )}
    </>
  )
}
