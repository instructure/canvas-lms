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
import {useMemo} from 'react'
import {useShallow} from 'zustand/react/shallow'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import {useAccessibilityScansStore} from '../../stores/AccessibilityScansStore'
import {calculateTotalIssuesCount, parseAccessibilityScans} from '../../utils/apiData'
import {IssuesByTypeChart} from './IssuesByTypeChart'
import {IssuesCounter} from './IssuesCounter'
import {AccessibilityData} from '../../types'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

function renderLoading() {
  return (
    <View as="div" width="100%" textAlign="center" height="270px">
      <Spinner renderTitle={I18n.t('Loading accessibility issues')} size="large" margin="auto" />
    </View>
  )
}

export const AccessibilityIssuesSummary = () => {
  const [accessibilityScans, loading] = useAccessibilityScansStore(
    useShallow(state => [state.accessibilityScans, state.loading]),
  )

  const issues = useMemo(() => {
    return accessibilityScans
      ? parseAccessibilityScans(accessibilityScans)
      : ({} as AccessibilityData)
  }, [accessibilityScans])

  if (window.ENV.SCAN_DISABLED === true) return null

  if (loading) return renderLoading()

  return (
    <Flex margin="0" gap="small" alignItems="stretch" data-testid="accessibility-issues-summary">
      <Flex.Item>
        <View as="div" padding="medium" borderWidth="small" borderRadius="medium" height="100%">
          <IssuesCounter count={calculateTotalIssuesCount(accessibilityScans)} />
        </View>
      </Flex.Item>
      <Flex.Item shouldGrow shouldShrink>
        <View as="div" padding="x-small" borderWidth="small" borderRadius="medium" height="100%">
          <IssuesByTypeChart accessibilityIssues={issues} isLoading={loading} />
        </View>
      </Flex.Item>
    </Flex>
  )
}
