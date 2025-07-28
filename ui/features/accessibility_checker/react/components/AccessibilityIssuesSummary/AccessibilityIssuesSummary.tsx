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

import {useShallow} from 'zustand/react/shallow'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import {useAccessibilityCheckerStore} from '../../stores/AccessibilityCheckerStore'
import {calculateTotalIssuesCount} from '../../utils'
import {IssuesByTypeChart} from './IssuesByTypeChart'
import {IssuesCounter} from './IssuesCounter'

export const AccessibilityIssuesSummary = () => {
  const [accessibilityIssues, accessibilityScanDisabled, loading] = useAccessibilityCheckerStore(
    useShallow(state => [
      state.accessibilityIssues,
      state.accessibilityScanDisabled,
      state.loading,
    ]),
  )

  if (accessibilityScanDisabled || loading) return null

  return (
    <Flex
      margin="medium 0 0 0"
      gap="small"
      alignItems="stretch"
      data-testid="accessibility-issues-summary"
    >
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
