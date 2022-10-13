/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {View} from '@instructure/ui-view'

import SearchItemSelector from '@canvas/search-item-selector/react/SearchItemSelector'

const I18n = useI18nScope('jobs_v2')

function convertResult(json) {
  return Object.entries(json).map(item => ({id: item[0], name: item[0], count: item[1]}))
}

function useJobSearchApi(fetchApiOpts) {
  useFetchApi({
    forceResult: (fetchApiOpts.params.term?.length || 0) === 0 ? [] : undefined,
    path: `/api/v1/jobs2/${fetchApiOpts.params.bucket}/by_${fetchApiOpts.params.group}/search`,
    convert: convertResult,
    ...fetchApiOpts,
  })
}

export default function SearchBox({bucket, group, setSelectedItem, manualSelection}) {
  return (
    <SearchItemSelector
      onItemSelected={setSelectedItem}
      renderLabel={I18n.t('Filter %{bucket} jobs by %{group}', {bucket, group})}
      itemSearchFunction={useJobSearchApi}
      manualSelection={manualSelection}
      additionalParams={{bucket, group}}
      renderOption={item => {
        return (
          <View>
            {item.name} ({item.count})
          </View>
        )
      }}
    />
  )
}
