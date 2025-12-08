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
import {useScope as createI18nScope} from '@canvas/i18n'
import {BorderWidth} from '@instructure/emotion/types/styleUtils'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {IconTextLine} from '@instructure/ui-icons'
import {Mask} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'

import {IssueCountBadge} from '../../../../shared/react/components/IssueCountBadge/IssueCountBadge'
import {useAccessibilityScansStore} from '../../../../shared/react/stores/AccessibilityScansStore'
import {AccessibilityIssuesSummaryData} from '../../../../shared/react/types'

import {IssueSummaryGroups, IssueSummaryGroupData} from '../../constants'
import {getGroupedIssueSummaryData} from '../../utils/groupedSummary'
import IssueTypeSummaryRow from './IssueTypeSummaryRow'

const I18n = createI18nScope('accessibility_checker')

type PreviewOverlayProps = {
  loading?: boolean
  error?: string | null
}

const getBorderWidth = (index: number, total: number): BorderWidth => {
  const isFirst = index === 0
  const isLast = index === total - 1

  if (isFirst && isLast) return 'small'
  if (isFirst) return 'small small none small'
  if (isLast) return 'small'
  return 'small small none small'
}

const PreviewOverlay = ({loading, error}: PreviewOverlayProps) => {
  if (error) {
    return (
      <Mask data-testid="grouped-issue-summary-error-overlay">
        <Alert
          variant="error"
          renderCloseButtonLabel={I18n.t('Close alert')}
          variantScreenReaderLabel={I18n.t('Error, ')}
        >
          {error}
        </Alert>
      </Mask>
    )
  }

  if (loading) {
    return (
      <Mask data-testid="grouped-issue-summary-loading-overlay">
        <Spinner renderTitle={I18n.t('Loading preview...')} size="large" />
      </Mask>
    )
  }

  return null
}

const GroupedIssueSummaryHeader = ({
  issuesSummary,
}: {
  issuesSummary: AccessibilityIssuesSummaryData | null
}) => {
  return (
    <Flex alignItems="center" gap="small">
      <Flex.Item>
        <Text size="large" weight="bold">
          Accessibility issues summary
        </Text>
      </Flex.Item>
      {issuesSummary?.total && (
        <Flex.Item data-testid="grouped-issue-summary-total-badge">
          <IssueCountBadge issueCount={issuesSummary?.total} />
        </Flex.Item>
      )}
    </Flex>
  )
}

const GroupedIssueSummaryFooter = ({
  issuesSummary,
  onBackClick,
  onReviewAndFixClick,
}: {
  issuesSummary: AccessibilityIssuesSummaryData | null
  onBackClick?: () => void
  onReviewAndFixClick?: () => void
}) => {
  return (
    <Flex gap="small" justifyItems="start">
      <Flex.Item>
        <Button
          color="primary"
          data-testid="grouped-issue-summary-review-fix"
          disabled={!issuesSummary || issuesSummary.total === 0}
          onClick={onReviewAndFixClick}
        >
          {I18n.t('Review and fix')}
        </Button>
      </Flex.Item>
      <Flex.Item>
        <Button data-testid="grouped-issue-summary-back" onClick={onBackClick}>
          {I18n.t('Back to accessibility checker')}
        </Button>
      </Flex.Item>
    </Flex>
  )
}

export type GroupedIssueSummaryProps = {
  onBackClick?: () => void
  onReviewAndFixClick?: () => void
}

export const GroupedIssueSummary = ({
  onBackClick,
  onReviewAndFixClick,
}: GroupedIssueSummaryProps) => {
  const [errorOfSummary, issuesSummary, loadingOfSummary] = useAccessibilityScansStore(
    useShallow(state => [state.errorOfSummary, state.issuesSummary, state.loadingOfSummary]),
  )

  const groupedIssueSummaryData = useMemo(
    () => getGroupedIssueSummaryData(issuesSummary?.byRuleType || {}),
    [issuesSummary],
  )

  return (
    <>
      <PreviewOverlay loading={loadingOfSummary} error={errorOfSummary} />

      <View as="div" width="full" aria-live="polite" data-testid="grouped-issue-summary">
        <Flex direction="column" gap="medium" margin="medium 0">
          <GroupedIssueSummaryHeader issuesSummary={issuesSummary} />

          <Flex direction="column" gap="none">
            {IssueSummaryGroups.map((group, index, filteredGroups) => {
              const count = groupedIssueSummaryData?.[group] ?? 0
              return (
                <IssueTypeSummaryRow
                  key={group}
                  count={count}
                  icon={IssueSummaryGroupData[group]?.icon || IconTextLine}
                  label={IssueSummaryGroupData[group]?.label || group}
                  borderWidth={getBorderWidth(index, filteredGroups.length)}
                />
              )
            })}
          </Flex>

          <GroupedIssueSummaryFooter
            issuesSummary={issuesSummary}
            onBackClick={onBackClick}
            onReviewAndFixClick={onReviewAndFixClick}
          />
        </Flex>
      </View>
    </>
  )
}
