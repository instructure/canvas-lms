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

import {useState} from 'react'

const DEFAULT_FILTER_SETTINGS: FilterSetting = {
  contentSubtype: 'all',
  contentType: 'links',
  sortValue: 'date_added',
  searchString: '',
}

export function useFilterSettings(
  default_settings?: FilterSetting,
): [FilterSetting, (nextSettings: FilterSetting) => void] {
  const [filterSettings, setFilterSettings] = useState(default_settings || DEFAULT_FILTER_SETTINGS)

  function updateFilterSettings(nextSettings: NewFilterSetting) {
    setFilterSettings({...filterSettings, ...nextSettings})
  }

  return [filterSettings, updateFilterSettings]
}

type FilterSetting = {
  contentType: string
  contentSubtype: string
  sortValue: string
  searchString: string
  sortDir?: string
  contextType?: string
}

type NewFilterSetting = {
  contentType?: string
  contentSubtype?: string
  sortValue?: string
  sortDir?: string
  searchString?: string
  contextType?: string
}
