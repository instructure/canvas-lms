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

import {useCallback, useContext, useEffect, useState} from 'react'
import doFetchApi, {DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {TypeToKeyMap} from '../../constants'
import {AccessibilityData, ContentItem} from '../../types'
import {
  calculateTotalIssuesCount,
  convertKeysToCamelCase,
  processAccessibilityData,
} from '../../utils'

import type {TableSortState} from '../AccessibilityIssuesTable/AccessibilityIssuesTable'
import {IssuesCounter} from './IssuesCounter'
import {AccessibilityCheckerContext} from '../../contexts/AccessibilityCheckerContext'
import AccessibilityIssuesTablePaginated from '../AccessibilityIssuesTable/AccessibilityIssuesTablePaginated'
import {IssuesByTypeChart} from '../IssuesByTypeChart/IssuesByTypeChart'

const I18n = createI18nScope('accessibility_checker')
const ISSUES_PER_PAGE = 10
const LIMIT_EXCEEDED_MESSAGE = I18n.t(
  'The Course Accessibility Checker is not yet available for courses with more than 1,000 resources (pages, assignments, and attachments combined).',
)
export const AccessibilityCheckerApp: React.FC = () => {
  const context = useContext(AccessibilityCheckerContext)
  const {setSelectedItem, setIsTrayOpen} = context
  const [accessibilityIssues, setAccessibilityIssues] = useState<AccessibilityData | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [tableData, setTableData] = useState<ContentItem[]>([])
  const [tableSortState, setTableSortState] = useState<TableSortState>({})
  const [accessibilityScanDisabled, setAccessibilityScanDisabled] = useState(false)

  const doFetchAccessibilityIssues = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data: DoFetchApiResults<any> = await doFetchApi({
        path: window.location.href + '/issues',
        method: 'POST',
      })

      const accessibilityIssues = convertKeysToCamelCase(data.json) as AccessibilityData
      if (accessibilityIssues.accessibilityScanDisabled) {
        setAccessibilityScanDisabled(true)
      }
      setAccessibilityIssues(accessibilityIssues)
      setTableData(processAccessibilityData(accessibilityIssues))
    } catch (err: any) {
      setError('Error loading accessibility issues. Error is:' + err.message)
      setAccessibilityIssues(null)
      setTableData([])
    } finally {
      setLoading(false)
    }
  }, [setAccessibilityIssues, setTableData, setError, setLoading])

  useEffect(() => {
    doFetchAccessibilityIssues()
  }, [doFetchAccessibilityIssues])

  const handleRowClick = useCallback(
    (item: ContentItem) => {
      const typeKey = TypeToKeyMap[item.type]

      const contentItem = accessibilityIssues?.[typeKey]?.[item.id]
        ? structuredClone(accessibilityIssues[typeKey]?.[item.id])
        : undefined

      setSelectedItem({
        ...item,
        issues: contentItem?.issues || [],
      })
      setIsTrayOpen(true)
    },
    [accessibilityIssues, setSelectedItem, setIsTrayOpen],
  )

  const handleReload = useCallback(() => {
    window.location.reload()
  }, [])

  const handleSortRequest = useCallback(
    (sortId?: string, sortDirection?: 'ascending' | 'descending' | 'none') => {
      try {
        setLoading(true)
        // TODO invoke backend API with the new values to sort the data
        // Then update states accordingly
        setTableSortState({
          sortId,
          sortDirection,
        })
      } catch {
        // Showing an error alert on the page
      } finally {
        setLoading(false)
      }
    },
    [setLoading, setTableSortState],
  )

  const lastCheckedDate =
    (accessibilityIssues?.lastChecked &&
      new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
      }).format(new Date(accessibilityIssues.lastChecked))) ||
    I18n.t('Unknown')

  const renderChartAndCounter = () => {
    return (
      <Flex margin="medium 0 0 0" gap="small" alignItems="stretch">
        <Flex.Item>
          <View as="div" padding="medium" borderWidth="small" borderRadius="medium" height="100%">
            <IssuesCounter count={calculateTotalIssuesCount(accessibilityIssues)} />
          </View>
        </Flex.Item>
        <Flex.Item shouldGrow shouldShrink>
          <View as="div" padding="x-small" borderWidth="small" borderRadius="medium" height="100%">
            <IssuesByTypeChart accessibilityIssues={accessibilityIssues} isLoading={loading} />
          </View>
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <View as="div">
      <Flex direction="column">
        {accessibilityScanDisabled && (
          <Alert
            variant="info"
            renderCloseButtonLabel="Close"
            onDismiss={() => {}}
            margin="small 0"
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
      {accessibilityScanDisabled || loading ? null : renderChartAndCounter()}
      <AccessibilityIssuesTablePaginated
        isLoading={loading}
        error={error}
        onRowClick={handleRowClick}
        onSortRequest={handleSortRequest}
        tableData={tableData}
        tableSortState={tableSortState}
        perPage={ISSUES_PER_PAGE}
      />
    </View>
  )
}
