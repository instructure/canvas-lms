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

import React, {useRef} from 'react'
import type {FilterItem} from '../../models/Filter'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import type {DiscoverParams} from '../../hooks/useDiscoverQueryParams'

const I18n = createI18nScope('lti_registrations')

export default function FilterTags(props: {
  numberOfResults: number
  queryParams: DiscoverParams
  updateQueryParams: (params: Partial<DiscoverParams>) => void
}) {
  const tagRefs = useRef<Tag[]>([])

  const removeFilter = (filter: FilterItem, index: number) => {
    const newFilters = Object.fromEntries(
      Object.entries(props.queryParams.filters).map(([key, value]) => [
        key,
        (value as FilterItem[]).filter(f => f.id !== filter.id),
      ]),
    )
    props.updateQueryParams({
      filters: newFilters,
      page: 1,
    })

    if (index > 0) {
      tagRefs.current[index - 1]?.focus()
    } else if (index === 0 && tagRefs.current.length > 1) {
      tagRefs.current[index + 1]?.focus()
    } else {
      const filterButton = document.getElementById('apply_filter')
      filterButton?.focus()
    }

    tagRefs.current.splice(index, 1)
  }

  return (
    <>
      <Flex gap="x-small" wrap="no-wrap" margin="0 0 medium 0">
        <p>
          {props.numberOfResults} {I18n.t('results filtered by')}
        </p>
        {(Object.values(props.queryParams.filters) as FilterItem[][])
          .flat()
          .map((filter: FilterItem, index: number) => {
            return (
              <Flex.Item padding="0 small 0 0" key={filter.id}>
                <Tag
                 ref={el => el && (tagRefs.current[index] = el)}
                 text={
                    <AccessibleContent alt={I18n.t('Remove filter %{filterName}', {filterName: filter.name})}>
                      {filter.name}
                    </AccessibleContent>
                  }
                  dismissible={true}
                  onClick={() => removeFilter(filter, index)}
                />
              </Flex.Item>
            )
          })}
        {props.queryParams.search && (
          <Flex.Item padding="0 small 0 0">
            <Tag
              text={'"' + props.queryParams.search + '"'}
              dismissible={true}
              onClick={() => props.updateQueryParams({search: '', page: 1})}
            />
          </Flex.Item>
        )}
      </Flex>
    </>
  )
}
