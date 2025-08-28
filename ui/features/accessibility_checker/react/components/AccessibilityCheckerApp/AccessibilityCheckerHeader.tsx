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

import {useCallback} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

import {LIMIT_EXCEEDED_MESSAGE} from '../../constants'
import {useAccessibilityScansStore} from '../../stores/AccessibilityScansStore'
import {AccessibilityData} from '../../types'

const I18n = createI18nScope('accessibility_checker')

const getLastCheckedDate = (accessibilityIssues?: AccessibilityData) => {
  return (
    (accessibilityIssues?.lastChecked &&
      new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
      }).format(new Date(accessibilityIssues.lastChecked))) ||
    I18n.t('Unknown')
  )
}

export const AccessibilityCheckerHeader: React.FC = () => {
  const [accessibilityScans, filters, loading] = useAccessibilityScansStore(
    useShallow(state => [state.accessibilityScans, state.filters, state.loading, state.search]),
  )

  const [setFilters, setLoading, setSearch] = useAccessibilityScansStore(
    useShallow(state => [state.setFilters, state.setLoading, state.setSearch]),
  )

  const lastCheckedDate = null // TODO Calculate with getLastCheckedDate(), Currently unavailable with the async API.

  const accessibilityScanDisabled = window.ENV.SCAN_DISABLED

  return (
    <>
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
        </Flex>
      </Flex>

      {lastCheckedDate && (
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
      )}
    </>
  )
}
