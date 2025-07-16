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

import {useCallback, useContext, useEffect} from 'react'
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
import {useAccessibilityCheckerStore} from '../../stores/AccessibilityCheckerStore'
import {ContentItem} from '../../types'
import {AccessibilityIssuesSummary} from '../AccessibilityIssuesSummary/AccessibilityIssuesSummary'
import {AccessibilityIssuesTable} from '../AccessibilityIssuesTable/AccessibilityIssuesTable'
import {useAccessibilityFetchUtils} from './useAccessibilityFetchUtils'

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityCheckerApp: React.FC = () => {
  const context = useContext(AccessibilityCheckerContext)
  const {setSelectedItem, setIsTrayOpen} = context
  const {parseFetchParams, doFetchAccessibilityIssues} = useAccessibilityFetchUtils()

  const [accessibilityIssues, accessibilityScanDisabled, loading] = useAccessibilityCheckerStore(
    useShallow(state => [
      state.accessibilityIssues,
      state.accessibilityScanDisabled,
      state.loading,
    ]),
  )

  useEffect(() => {
    doFetchAccessibilityIssues(parseFetchParams())
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

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

  const lastCheckedDate =
    (accessibilityIssues?.lastChecked &&
      new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
      }).format(new Date(accessibilityIssues.lastChecked))) ||
    I18n.t('Unknown')

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
      <AccessibilityIssuesSummary />
      <AccessibilityIssuesTable onRowClick={handleRowClick} />
    </View>
  )
}
