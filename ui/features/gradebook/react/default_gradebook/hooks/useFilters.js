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

import {useState, useEffect} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import I18n from 'i18n!gradebook'

const useFilters = (courseId, filtersEnabled) => {
  const [loading, setLoading] = useState(filtersEnabled)
  const [errors, setErrors] = useState([])
  const [data, setData] = useState([])

  useEffect(() => {
    const path = `/api/v1/courses/${courseId}/gradebook_filters`
    if (filtersEnabled) {
      doFetchApi({path})
        .then(response => {
          const filters = response.json.map(({gradebook_filter: filter}) => ({
            id: filter.id,
            label: filter.name,
            conditions: filter.payload.conditions || [],
            isApplied: !!filter.payload.isApplied,
            createdAt: filter.created_at
          }))
          setData(filters)
          setLoading(false)
        })
        .catch(() => {
          setErrors([
            {
              key: 'filters-loading-error',
              message: I18n.t('There was an error fetching gradebook filters.'),
              variant: 'error'
            }
          ])
          setLoading(false)
        })
    }
  }, [courseId, filtersEnabled])

  return {loading, errors, data, setData}
}

export default useFilters
