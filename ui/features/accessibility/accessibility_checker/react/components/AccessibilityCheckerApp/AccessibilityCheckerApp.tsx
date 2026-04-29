/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useCallback, useMemo, useEffect, useRef} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {View} from '@instructure/ui-view'

import {useAccessibilityScansFetchUtils} from '../../../../shared/react/hooks/useAccessibilityScansFetchUtils'
import {useAccessibilityScansStore} from '../../../../shared/react/stores/AccessibilityScansStore'
import {Filters} from '../../../../shared/react/types'
import {parseFetchParams} from '../../../../shared/react/utils/query'
import {AccessibilityIssuesSummary} from '../AccessibilityIssuesSummary/AccessibilityIssuesSummary'
import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable/AccessibilityIssuesTable'
import {SearchIssue} from './Search/SearchIssue'
import {useDeepCompareEffect} from './useDeepCompareEffect'
import {AccessibilityCheckerHeader} from './AccessibilityCheckerHeader'
import {FiltersPanel} from './Filter'
import {getAppliedFilters} from '../../utils/filter'

export const AccessibilityCheckerApp: React.FC = () => {
  const {doFetchAccessibilityScanData, doFetchAccessibilityIssuesSummary} =
    useAccessibilityScansFetchUtils()

  const [filters] = useAccessibilityScansStore(useShallow(state => [state.filters]))

  const [setFilters, setLoading, setSearch] = useAccessibilityScansStore(
    useShallow(state => [state.setFilters, state.setLoading, state.setSearch]),
  )

  const appliedFilters = useMemo(() => getAppliedFilters(filters || {}), [filters])

  const accessibilityScanDisabled = window.ENV.SCAN_DISABLED
  const hasInitializedFilters = useRef(false)

  useEffect(() => {
    const parsedFetchParams = parseFetchParams()
    if (parsedFetchParams.filters && !filters) {
      setFilters(parsedFetchParams.filters as Filters)
    } else {
      hasInitializedFilters.current = true
    }
  }, [])

  useDeepCompareEffect(() => {
    const fetchParams = parseFetchParams()
    if (fetchParams.filters && !filters && !hasInitializedFilters.current) {
      return // wait for filters to be set from query params on initial load
    }

    hasInitializedFilters.current = true

    if (!accessibilityScanDisabled) {
      const parsedFetchParams = {...fetchParams, filters, page: 1}
      doFetchAccessibilityScanData(parsedFetchParams)
      doFetchAccessibilityIssuesSummary(parsedFetchParams)
    } else {
      setLoading(false)
    }
  }, [accessibilityScanDisabled, setLoading, filters])

  const handleSearchChange = useCallback(
    async (value: string): Promise<boolean> => {
      const newSearch = value
      setSearch(newSearch)
      if (newSearch.length >= 0) {
        const params = {...parseFetchParams(), search: newSearch, filters, page: 1}

        const results = await Promise.allSettled([
          doFetchAccessibilityIssuesSummary(params),
          doFetchAccessibilityScanData(params),
        ])

        return results.every(result => result.status === 'fulfilled')
      }

      return false
    },
    [setSearch, doFetchAccessibilityScanData, doFetchAccessibilityIssuesSummary, filters],
  )

  return (
    <View as="div" data-testid="accessibility-checker-app">
      <AccessibilityCheckerHeader />
      <SearchIssue onSearchChange={handleSearchChange} />
      <FiltersPanel appliedFilters={appliedFilters} onFilterChange={setFilters} />
      <View as="div" margin={appliedFilters.length === 0 ? 'medium 0' : 'small 0'}>
        <AccessibilityIssuesSummary />
      </View>
      <AccessibilityIssuesTable />
    </View>
  )
}
