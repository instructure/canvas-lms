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

import {useCallback, useContext, useState} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {LIMIT_EXCEEDED_MESSAGE, TypeToKeyMap} from '../../constants'
import {AccessibilityCheckerContext} from '../../contexts/AccessibilityCheckerContext'
import {useAccessibilityFetchUtils} from '../../hooks/useAccessibilityFetchUtils'
import {useAccessibilityScansFetchUtils} from '../../hooks/useAccessibilityScansFetchUtils'
import {useNextResource} from '../../hooks/useNextResource'
import {useAccessibilityCheckerStore} from '../../stores/AccessibilityCheckerStore'
import {
  USE_ACCESSIBILITY_SCANS_STORE,
  useAccessibilityScansStore,
} from '../../stores/AccessibilityScansStore'
import {ContentItem, Filters} from '../../types'
import {parseFetchParams as parseFetchParamsN} from '../../utils/query'
import {AccessibilityIssuesSummary} from '../AccessibilityIssuesSummary/AccessibilityIssuesSummary'
import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable/AccessibilityIssuesTable'
import FiltersPopover from './Filter/FiltersPopover'

import SearchIssue from './Search/SearchIssue'
import {useDeepCompareEffect} from './useDeepCompareEffect'

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityCheckerApp: React.FC = () => {
  const context = useContext(AccessibilityCheckerContext)
  const {setSelectedItem, setIsTrayOpen} = context

  const {getNextResource} = useNextResource()

  const {doFetchAccessibilityScanData} = useAccessibilityScansFetchUtils()

  const [accessibilityScans, loadingN, setLoadingN, filters, setFilters] =
    useAccessibilityScansStore(
      useShallow(state => [
        state.accessibilityScans,
        state.loading,
        state.setLoading,
        state.filters,
        state.setFilters,
      ]),
    )

  const {doFetchAccessibilityIssues, parseFetchParams} = useAccessibilityFetchUtils()

  const [accessibilityIssues, loading, orderedTableData, setLoading, setNextResource, setSearch] =
    useAccessibilityCheckerStore(
      useShallow(state => [
        state.accessibilityIssues,
        state.loading,
        state.orderedTableData,
        state.setLoading,
        state.setNextResource,
        state.setSearch,
      ]),
    )

  const accessibilityScanDisabled = window.ENV.SCAN_DISABLED

  useDeepCompareEffect(() => {
    if (!accessibilityScanDisabled) {
      if (USE_ACCESSIBILITY_SCANS_STORE) {
        doFetchAccessibilityScanData(parseFetchParamsN(), filters)
      } else {
        doFetchAccessibilityIssues(parseFetchParams())
      }
    } else {
      setLoadingN(false)
      setLoading(false)
    }
  }, [accessibilityScanDisabled, setLoading, setLoadingN, filters])

  const handleRowClick = useCallback(
    (item: ContentItem) => {
      const typeKey = TypeToKeyMap[item.type]

      const contentItem = accessibilityIssues?.[typeKey]?.[item.id]
        ? structuredClone(accessibilityIssues[typeKey]?.[item.id])
        : undefined
      const updatedItem = {
        ...item,
        issues: contentItem?.issues || [],
      }
      setSelectedItem(updatedItem)
      setIsTrayOpen(true)
      if (orderedTableData) {
        const nextResource = getNextResource(orderedTableData, updatedItem)
        if (nextResource) {
          setNextResource(nextResource)
        }
      }
    },
    [
      accessibilityIssues,
      setSelectedItem,
      setIsTrayOpen,
      orderedTableData,
      getNextResource,
      setNextResource,
    ],
  )

  const handleSearchChange = useCallback(
    async (value: string) => {
      const newSearch = value
      setSearch(newSearch)
      if (newSearch.length >= 0) {
        await doFetchAccessibilityIssues({search: newSearch, page: 0})
      }
    },
    [setSearch, doFetchAccessibilityIssues],
  )

  const handleReload = useCallback(() => {
    window.location.reload()
  }, [])

  const lastCheckedDate =
    (accessibilityIssues?.lastChecked &&
      new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
      }).format(new Date(accessibilityIssues.lastChecked))) ||
    I18n.t('Unknown')

  return (
    <View as="div" data-testid="accessibility-checker-app">
      <Flex direction="column">
        {accessibilityScanDisabled && (
          <Alert
            variant="info"
            renderCloseButtonLabel="Close"
            onDismiss={() => {}}
            margin="small 0"
            data-testid="accessibility-scan-disabled-alert"
          >
            {LIMIT_EXCEEDED_MESSAGE}
          </Alert>
        )}
        <Flex as="div" alignItems="start" direction="row">
          <Flex.Item>
            <Heading level="h1">{I18n.t('Course Accessibility Checker')}</Heading>
          </Flex.Item>
          {!loading && !accessibilityScanDisabled && (
            <Flex.Item margin="0 0 0 auto" padding="small 0">
              <Button color="primary" onClick={handleReload} disabled={accessibilityScanDisabled}>
                {I18n.t('Check Accessibility')}
              </Button>
            </Flex.Item>
          )}
        </Flex>
      </Flex>

      <Flex as="div" alignItems="start" direction="row">
        {lastCheckedDate && (
          <Flex.Item>
            <Text size="small" color="secondary">
              <>
                {I18n.t('Last checked at ')}
                {lastCheckedDate}
              </>
            </Text>
          </Flex.Item>
        )}
      </Flex>

      <Flex alignItems="start" direction="row" margin="small 0">
        <Flex.Item width="100%">
          <Flex justifyItems="space-between" gap="small">
            <SearchIssue onSearchChange={handleSearchChange} />
            {USE_ACCESSIBILITY_SCANS_STORE && <FiltersPopover onFilterChange={setFilters} />}
          </Flex>
        </Flex.Item>
      </Flex>
      <AccessibilityIssuesSummary />
      <AccessibilityIssuesTable onRowClick={handleRowClick} />
    </View>
  )
}
