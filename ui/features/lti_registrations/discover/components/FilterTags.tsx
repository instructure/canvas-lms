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

import React, {useState, useEffect} from 'react'
import type {LtiFilter} from '../model/Filter'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {useSearchParams} from 'react-router-dom'

const I18n = useI18nScope('lti_registrations')

export default function FilterTags(props: {filterValues: LtiFilter}) {
  const [searchParams, setSearchParams] = useSearchParams()
  const [filterIds, setFilterIds] = useState<number[]>([])

  useEffect(() => {
    const queryParams = searchParams.get('filter')
    const params = queryParams ? JSON.parse(queryParams) : []
    const ids: number[] = Object.values(params) as number[]
    setFilterIds(ids)
  }, [searchParams])

  const removeFilter = (id: number) => {
    const newFilterIds = filterIds.filter(i => i !== id)
    setSearchParams({filter: JSON.stringify(newFilterIds)})
  }

  const findFilterName = (id: number) => {
    const filter = Object.values(props.filterValues)
      .flat()
      .find(f => f.id === id)
    return filter ? filter.name : ''
  }

  return (
    <Flex margin="0 0 medium 0">
      {filterIds.length > 0 && (
        // TODO: add number of results
        <Flex.Item padding="0 small 0 0"> {I18n.t('results filtered by')}</Flex.Item>
      )}
      {filterIds.map(id => {
        return (
          <Flex.Item padding="0 small 0 0" key={id}>
            <Tag text={findFilterName(id)} dismissible={true} onClick={() => removeFilter(id)} />
          </Flex.Item>
        )
      })}
    </Flex>
  )
}
