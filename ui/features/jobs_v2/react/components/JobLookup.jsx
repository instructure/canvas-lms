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
import {Pill} from '@instructure/ui-pill'

import SearchItemSelector from '@canvas/search-item-selector/react/SearchItemSelector'

const I18n = useI18nScope('jobs_v2')

function convertResult(json) {
  return json.map(item => ({...item, name: item.id.toString()}))
}

function useJobLookupApi(fetchApiOpts) {
  useFetchApi({
    forceResult: (fetchApiOpts.params.term?.length || 0) === 0 ? [] : undefined,
    path: `/api/v1/jobs2/${fetchApiOpts.params.term}`,
    convert: convertResult,
    ...fetchApiOpts,
  })
}

export default function JobLookup({setSelectedItem, manualSelection}) {
  return (
    <SearchItemSelector
      onItemSelected={setSelectedItem}
      renderLabel={I18n.t('Job lookup')}
      placeholder={I18n.t('Enter an id or an original_job_id')}
      itemSearchFunction={useJobLookupApi}
      manualSelection={manualSelection}
      isSearchableTerm={term => term.length > 0 && term.match(/^\d+$/)?.length > 0}
      renderOption={item => {
        return (
          <View>
            <strong>{item.id}</strong> {item.tag}{' '}
            <Pill margin="x-small" color={item.bucket === 'failed' ? 'warning' : 'info'}>
              {item.bucket}
            </Pill>
          </View>
        )
      }}
    />
  )
}
