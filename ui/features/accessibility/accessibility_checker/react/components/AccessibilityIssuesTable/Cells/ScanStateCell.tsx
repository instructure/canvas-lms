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
import {Flex, FlexItemProps} from '@instructure/ui-flex'
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
  isMobile: boolean
}

const ISSUES_COUNT_OFFSET = '2.75rem'
const getDesktopProps = (isMobile: boolean) => {
  if (isMobile) {
    return {}
  }
  return {size: ISSUES_COUNT_OFFSET, textAlign: 'end'} as FlexItemProps
}

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

const IssueCountAndAction = ({item, isMobile}: ScanStateCellProps) => (
  <Flex gap="x-small">
    <Flex.Item {...getDesktopProps(isMobile)}>
      <Flex justifyItems="end">
        <IssueCountBadge issueCount={item.issueCount} />
      </Flex>
    </Flex.Item>
    <FixOrReviewAction item={item} isMobile={isMobile} />
  </Flex>
)

interface ScanStateWithIconProps {
  icon: React.ReactNode
  text: any
  isMobile: boolean
}

const ScanStateWithIcon = ({icon, text, isMobile}: ScanStateWithIconProps) => (
  <Flex gap="x-small">
    <Flex.Item {...getDesktopProps(isMobile)}>
      <Flex justifyItems="end">
        {icon}
      </Flex>
    </Flex.Item>
    <Flex.Item textAlign="start">
      <Text>{text}</Text>
    </Flex.Item>
  </Flex>
)

interface ExplanationProps {
  icon: React.ReactNode
  tooltipText: string
}

const Explanation = ({icon, tooltipText}: ExplanationProps) => (
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

interface ScanStateWithExplanationProps {
  icon: React.ReactNode
  text: string
  tooltipText: string
  isMobile: boolean
}

const ScanStateWithExplanation = ({
  icon,
  text,
  tooltipText,
  isMobile,
}: ScanStateWithExplanationProps) => (
  <Flex gap="x-small">
    <Flex.Item {...getDesktopProps(isMobile)}>
      <Explanation icon={icon} tooltipText={tooltipText} />
    </Flex.Item>
    <Flex.Item textAlign="start">
      <Text>{text}</Text>
    </Flex.Item>
  </Flex>
)

const NoIssuesText = ({isMobile}: {isMobile: boolean}) => (
  <ScanStateWithIcon
    icon={<IconPublishSolid color="success" aria-hidden="true"/>}
    text={I18n.t('No issues')}
    isMobile={isMobile}
  />
)

const ScanInProgress = ({item, isMobile}: {item: AccessibilityResourceScan; isMobile: boolean}) => (
  <ScanStateWithIcon
    icon={
      <Spinner
        size="x-small"
        renderTitle={I18n.t('Scan in progress for %{name}', {name: item.resourceName})}
      />
    }
    text={I18n.t('Checking...')}
    isMobile={isMobile}
  />
)

// Should not happen, as a scan either completes or fails, but just in case...
const UnknownIssuesText = ({isMobile}: {isMobile: boolean}) => (
  <ScanStateWithIcon
    icon={<IconQuestionLine color="secondary" aria-hidden="true" />}
    text={I18n.t('Unknown')}
    isMobile={isMobile}
  />
)

const ScanWithError = ({item, isMobile}: {item: AccessibilityResourceScan; isMobile: boolean}) => (
  <ScanStateWithExplanation
    icon={<IconQuestionLine color="secondary" aria-hidden="true" />}
    text={I18n.t('Failed')}
    tooltipText={I18n.t('Scan error:') + ` ${item.errorMessage || I18n.t('Unknown error')}`}
    isMobile={isMobile}
  />
)

export const ScanStateCell: React.FC<ScanStateCellProps> = ({
  item,
  isMobile,
}: ScanStateCellProps) => {
  switch (item.workflowState) {
    case ScanWorkflowState.Queued:
    case ScanWorkflowState.InProgress: {
      return <ScanInProgress item={item} isMobile={isMobile} />
    }
    case ScanWorkflowState.Completed: {
      if (item.issueCount > 0) {
        return <IssueCountAndAction item={item} isMobile={isMobile} />
      } else if (item.issueCount === 0) {
        return <NoIssuesText isMobile={isMobile} />
      }
      break
    }
    case ScanWorkflowState.Failed: {
      return <ScanWithError item={item} isMobile={isMobile} />
    }
    default: {
      return <UnknownIssuesText isMobile={isMobile} />
    }
  }
}
