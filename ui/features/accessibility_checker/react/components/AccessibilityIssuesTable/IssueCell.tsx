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

import {Button} from '@instructure/ui-buttons'
import {IconEditLine, IconPublishSolid, IconQuestionLine} from '@instructure/ui-icons'
import {AccessibleContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'

import {useScope as createI18nScope} from '@canvas/i18n'

import {ContentItem} from '../../types'
import {Flex} from '@instructure/ui-flex'

interface IssueCellProps {
  item: ContentItem
  onClick?: (item: ContentItem) => void
}

const MAX_COUNT = 999

const I18n = createI18nScope('accessibility_checker')

const IssuePillAndButton = ({item, onClick}: IssueCellProps) => {
  const handleClick = useCallback(() => onClick?.(item), [item, onClick])
  return (
    <Flex gap="x-small">
      <Flex.Item>
        <Tag
          data-testid="issue-count-tag"
          text={
            <AccessibleContent
              alt={I18n.t(
                {
                  one: '1 Issue',
                  other: '%{count} Issues',
                  zero: 'No Issues',
                },
                {count: item.count},
              )}
            >
              {item.count > MAX_COUNT ? `${MAX_COUNT}+` : item.count}
            </AccessibleContent>
          }
          themeOverride={(_componentTheme, currentTheme) => ({
            defaultBackground: currentTheme.colors.primitives.orange57,
            defaultBorderColor: currentTheme.colors.primitives.orange57,
            defaultColor: currentTheme.colors.primitives.white,
          })}
        />
      </Flex.Item>
      {onClick && (
        <Flex.Item>
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

const NoIssuesText = () => (
  <Flex gap="x-small">
    <Flex.Item>
      <PresentationContent>
        <IconPublishSolid color="success" />
      </PresentationContent>
    </Flex.Item>
    <Flex.Item>
      <Text>{I18n.t('No issues')}</Text>
    </Flex.Item>
  </Flex>
)

const UnknownIssuesText = () => (
  <Flex gap="x-small">
    <Flex.Item>
      <PresentationContent>
        <IconQuestionLine color="secondary" />
      </PresentationContent>
    </Flex.Item>
    <Flex.Item>
      <Text>{I18n.t('Unknown')}</Text>
    </Flex.Item>
  </Flex>
)

const LoadingIssuesText = () => (
  <Flex gap="x-small">
    <Flex.Item>
      <PresentationContent>
        <Spinner size="x-small" />
      </PresentationContent>
    </Flex.Item>
    <Flex.Item>
      <Text>{I18n.t('Checking...')}</Text>
    </Flex.Item>
  </Flex>
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
