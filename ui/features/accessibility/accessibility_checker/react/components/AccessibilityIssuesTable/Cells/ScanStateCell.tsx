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

import {useScope as createI18nScope} from '@canvas/i18n'
import {theme} from '@instructure/canvas-theme'
import {
  AccessibleContent,
  PresentationContent,
  ScreenReaderContent,
} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconEditLine, IconPublishSolid, IconQuestionLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Tooltip} from '@instructure/ui-tooltip'

import {
  AccessibilityResourceScan,
  ResourceType,
  ScanWorkflowState,
} from '../../../../../shared/react/types'
import {IssueCountBadge} from '../../../../../shared/react/components/IssueCountBadge/IssueCountBadge'
import {useAccessibilityIssueSelect} from '../../../../../shared/react/hooks/useAccessibilityIssueSelect'
const I18n = createI18nScope('accessibility_checker')

interface ScanStateCellProps {
  item: AccessibilityResourceScan
}

const ISSUES_COUNT_OFFSET = '2.75rem'

const FixOrReviewAction = ({item}: ScanStateCellProps) => {
  const {selectIssue} = useAccessibilityIssueSelect()

  const canFix = item.resourceType !== ResourceType.Attachment
  const dataTestId = canFix ? 'issue-remediation-button' : 'issue-review-button'
  const text = canFix ? I18n.t('Fix') : I18n.t('Review')
  const altText = canFix
    ? I18n.t('Fix issues for %{name}', {name: item.resourceName})
    : I18n.t('Review issues for %{name}', {name: item.resourceName})

  const renderIcon = canFix ? <IconEditLine /> : null
  const courseId = window.ENV.current_context?.id ?? null

  const handleClick = useCallback(() => selectIssue(item), [item, selectIssue])

  return (
    <Flex.Item textAlign="start">
      {window.ENV.FEATURES?.accessibility_issues_in_full_page && courseId ? (
        <Link
          href={`/courses/${courseId}/accessibility_issues/${item.id}`}
          variant="standalone"
          data-testid={dataTestId}
        >
          <Button data-testid={dataTestId} size="small" renderIcon={renderIcon} onClick={() => {}}>
            <AccessibleContent alt={altText}>{text}</AccessibleContent>
          </Button>
        </Link>
      ) : (
        <Button data-testid={dataTestId} size="small" renderIcon={renderIcon} onClick={handleClick}>
          <AccessibleContent alt={altText}>{text}</AccessibleContent>
        </Button>
      )}
    </Flex.Item>
  )
}

const IssueCountAndAction = ({item}: ScanStateCellProps) => (
  <Flex gap="x-small">
    <Flex.Item textAlign="end" size={ISSUES_COUNT_OFFSET}>
      <IssueCountBadge issueCount={item.issueCount} />
    </Flex.Item>
    <FixOrReviewAction item={item} />
  </Flex>
)

interface ScanStateWithIconProps {
  icon: React.ReactNode
  text: any
}

const ScanStateWithIcon = ({icon, text}: ScanStateWithIconProps) => {
  return (
    <Flex gap="x-small">
      <Flex.Item textAlign="end" size={ISSUES_COUNT_OFFSET}>
        <PresentationContent>{icon}</PresentationContent>
      </Flex.Item>
      <Flex.Item textAlign="start">
        <Text>{text}</Text>
      </Flex.Item>
    </Flex>
  )
}

interface ExplanationProps {
  icon: React.ReactNode
  tooltipText: string
}

const Explanation = ({icon, tooltipText}: ExplanationProps) => {
  return (
    <Tooltip
      renderTip={tooltipText}
      placement="top"
      on={['hover', 'focus']}
      color="primary"
      data-testid="scan-state-explanation"
    >
      <span
        style={{display: 'inline-block', marginLeft: theme.spacing.xxSmall}}
        data-testid="scan-state-explanation-trigger"
        // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
        tabIndex={0}
      >
        {icon}
        <ScreenReaderContent>{tooltipText}</ScreenReaderContent>
      </span>
    </Tooltip>
  )
}

interface ScanStateWithExplanationProps {
  icon: React.ReactNode
  text: string
  tooltipText: string
}

const ScanStateWithExplanation = ({icon, text, tooltipText}: ScanStateWithExplanationProps) => {
  return (
    <Flex gap="x-small">
      <Flex.Item textAlign="end" size={ISSUES_COUNT_OFFSET}>
        <Explanation icon={icon} tooltipText={tooltipText} />
      </Flex.Item>
      <Flex.Item textAlign="start">
        <Text>{text}</Text>
      </Flex.Item>
    </Flex>
  )
}

const NoIssuesText = () => (
  <ScanStateWithIcon icon={<IconPublishSolid color="success" />} text={I18n.t('No issues')} />
)

const ScanInProgress = ({item}: {item: AccessibilityResourceScan}) => (
  <ScanStateWithIcon
    icon={
      <Spinner
        size="x-small"
        renderTitle={I18n.t('Scan in progress for %{name}', {name: item.resourceName})}
      />
    }
    text={I18n.t('Checking...')}
  />
)

// Should not happen, as a scan either completes or fails, but just in case...
const UnknownIssuesText = () => (
  <ScanStateWithIcon icon={<IconQuestionLine color="secondary" />} text={I18n.t('Unknown')} />
)

const ScanWithError = ({item}: {item: AccessibilityResourceScan}) => (
  <ScanStateWithExplanation
    icon={<IconQuestionLine color="secondary" />}
    text={I18n.t('Failed')}
    tooltipText={I18n.t('Scan error:') + ` ${item.errorMessage || I18n.t('Unknown error')}`}
  />
)

export const ScanStateCell: React.FC<ScanStateCellProps> = ({item}: ScanStateCellProps) => {
  switch (item.workflowState) {
    case ScanWorkflowState.Queued:
    case ScanWorkflowState.InProgress: {
      return <ScanInProgress item={item} />
    }
    case ScanWorkflowState.Completed: {
      if (item.issueCount > 0) {
        return <IssueCountAndAction item={item} />
      } else if (item.issueCount === 0) {
        return <NoIssuesText />
      }
      break
    }
    case ScanWorkflowState.Failed: {
      return <ScanWithError item={item} />
    }
    default: {
      return <UnknownIssuesText />
    }
  }
}
