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

import React, {useCallback} from 'react'

import {AccessibleContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Badge, BadgeProps} from '@instructure/ui-badge'
import {Button} from '@instructure/ui-buttons'
import {IconEditLine, IconPublishSolid, IconQuestionLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'

import {useScope as createI18nScope} from '@canvas/i18n'

import {ContentItem} from '../../types'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('accessibility_checker')

interface IssueCellProps {
  item: ContentItem
  onClick?: (item: ContentItem) => void
}

const MAX_COUNT = 100
const ISSUES_COUNT_OFFSET = '2.75rem'

const badgeThemeOverride: BadgeProps['themeOverride'] = (_componentTheme, currentTheme) => ({
  colorDanger: currentTheme.colors.primitives.orange45,
  fontWeight: 700,
  padding: '0.5rem',
  fontSize: '1rem',
  size: '1.375rem',
})

const IssuePillAndButton = ({item, onClick}: IssueCellProps) => {
  const handleClick = useCallback(() => onClick?.(item), [item, onClick])

  return (
    <Flex gap="x-small">
      <Flex.Item textAlign="end" size={ISSUES_COUNT_OFFSET}>
        <Badge
          standalone
          variant="danger"
          countUntil={MAX_COUNT}
          themeOverride={badgeThemeOverride}
          count={item.count}
          formatOverflowText={(_count: number, countUntil: number) => `${countUntil - 1}+`}
          formatOutput={formattedCount => {
            const altText =
              formattedCount === '1'
                ? I18n.t('1 Issue')
                : I18n.t('%{count} Issues', {count: formattedCount})

            return (
              <AccessibleContent alt={altText} data-testid="issue-count-badge">
                {formattedCount}
              </AccessibleContent>
            )
          }}
        />
      </Flex.Item>
      {onClick && (
        <Flex.Item textAlign="start">
          <Button
            data-testid="issue-remediation-button"
            size="small"
            renderIcon={<IconEditLine />}
            onClick={handleClick}
          >
            {I18n.t('Fix')}
          </Button>
        </Flex.Item>
      )}
    </Flex>
  )
}

interface NonFixableCellProps {
  icon: React.ReactNode
  text: any
}

const NonFixableCell = ({icon, text}: NonFixableCellProps) => {
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

const NoIssuesText = () => (
  <NonFixableCell icon={<IconPublishSolid color="success" />} text={I18n.t('No issues')} />
)

const UnknownIssuesText = () => (
  <NonFixableCell icon={<IconQuestionLine color="secondary" />} text={I18n.t('Unknown')} />
)

const LoadingIssuesText = () => (
  <NonFixableCell icon={<Spinner size="x-small" />} text={I18n.t('Checking...')} />
)

export const IssueCell: React.FC<IssueCellProps> = (props: IssueCellProps) => {
  const {item} = props
  if (item.count > 0) {
    return <IssuePillAndButton {...props} />
  } else if (item.count === 0) {
    return <NoIssuesText />
    // TODO: Handle the case when it is not scanned yet
  } else if (item.issues === undefined) {
    return <UnknownIssuesText />
  } else {
    // TODO: Handle the case when the scan process is running
    return <LoadingIssuesText />
  }
}
