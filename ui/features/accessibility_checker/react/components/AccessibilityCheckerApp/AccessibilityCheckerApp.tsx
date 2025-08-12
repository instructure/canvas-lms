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

import {useCallback, useContext, useMemo} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import {AccessibilityCheckerContext} from '../../contexts/AccessibilityCheckerContext'
import {useAccessibilityScansFetchUtils} from '../../hooks/useAccessibilityScansFetchUtils'
import {useNextResource} from '../../hooks/useNextResource'
import {useAccessibilityScansStore} from '../../stores/AccessibilityScansStore'
import {AccessibilityResourceScan} from '../../types'
import {parseFetchParams} from '../../utils/query'
import {AccessibilityIssuesSummary} from '../AccessibilityIssuesSummary/AccessibilityIssuesSummary'
import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable/AccessibilityIssuesTable'
import FiltersPopover from './Filter/FiltersPopover'
import {SearchIssue} from './Search/SearchIssue'
import {useDeepCompareEffect} from './useDeepCompareEffect'
import {AccessibilityCheckerHeader} from './AccessibilityCheckerHeader'
import {findById} from '../../utils/apiData'

import AppliedFilters from './Filter/AppliedFilters'
import {getAppliedFilters} from '../../utils/filter'

export const AccessibilityCheckerApp: React.FC = () => {
  const context = useContext(AccessibilityCheckerContext)
  const {setSelectedItem, setIsTrayOpen} = context

  const {getNextResource} = useNextResource()

  const {doFetchAccessibilityScanData} = useAccessibilityScansFetchUtils()

  const [accessibilityScans, filters] = useAccessibilityScansStore(
    useShallow(state => [state.accessibilityScans, state.filters]),
  )

  const [setFilters, setLoading, setNextResource, setSearch] = useAccessibilityScansStore(
    useShallow(state => [
      state.setFilters,
      state.setLoading,
      state.setNextResource,
      state.setSearch,
    ]),
  )

  const appliedFilters = useMemo(() => getAppliedFilters(filters || {}), [filters])

  const accessibilityScanDisabled = window.ENV.SCAN_DISABLED

  useDeepCompareEffect(() => {
    if (!accessibilityScanDisabled) {
      doFetchAccessibilityScanData(parseFetchParams(), filters)
    } else {
      setLoading(false)
    }
  }, [accessibilityScanDisabled, setLoading, filters])

  const handleRowClick = useCallback(
    (item: AccessibilityResourceScan) => {
      const originalItem: AccessibilityResourceScan | undefined = findById(
        accessibilityScans,
        item.id,
      )

      const updatedItem = {
        ...item,
        issues: originalItem?.issues || [],
      }
      setSelectedItem(updatedItem)
      setIsTrayOpen(true)

      if (accessibilityScans) {
        const nextResource = getNextResource(accessibilityScans, updatedItem)
        if (nextResource) {
          setNextResource(nextResource)
        }
      }
    },
    [accessibilityScans, setNextResource, setSelectedItem, setIsTrayOpen, getNextResource],
  )

  const handleSearchChange = useCallback(
    async (value: string) => {
      const newSearch = value
      setSearch(newSearch)
      if (newSearch.length >= 0) {
        await doFetchAccessibilityScanData({search: newSearch, page: 1})
      }
    },
    [setSearch, doFetchAccessibilityScanData],
  )

  return (
    <View as="div" data-testid="accessibility-checker-app">
      <AccessibilityCheckerHeader />
      <Flex alignItems="start" direction="row" margin="small 0">
        <Flex.Item width="100%">
          <Flex justifyItems="space-between" gap="small">
            <SearchIssue onSearchChange={handleSearchChange} />
            <FiltersPopover appliedFilters={appliedFilters} onFilterChange={setFilters} />
          </Flex>
        </Flex.Item>
      </Flex>
      <AppliedFilters appliedFilters={appliedFilters} setFilters={setFilters} />
      <View as="div" margin={appliedFilters.length === 0 ? 'medium 0' : 'small 0'}>
        <AccessibilityIssuesSummary />
      </View>
      <AccessibilityIssuesTable onRowClick={handleRowClick} />
    </View>
  )
}
