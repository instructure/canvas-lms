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

import {useState} from 'react'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {CondensedButton, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {IconInfoLine, IconExternalLinkLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AccessibilityIssue} from './types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('block_content_editor')

interface IssuesContentProps {
  currentIssue: AccessibilityIssue
  currentIssueIndex: number
  totalIssues: number
}

export const IssuesContent = ({
  currentIssue,
  currentIssueIndex,
  totalIssues,
}: IssuesContentProps) => {
  const [isInfoPopoverOpen, setIsInfoPopoverOpen] = useState(false)

  const handleShowInfoPopover = () => {
    setIsInfoPopoverOpen(true)
  }

  const handleHideInfoPopover = () => {
    setIsInfoPopoverOpen(false)
  }
  return (
    <View>
      <Flex alignItems="center" gap="x-small" margin="medium 0 small 0">
        <Text weight="bold">
          {I18n.t('Issue %{current}/%{total}', {
            current: currentIssueIndex + 1,
            total: totalIssues,
          })}
        </Text>
        <Popover
          isShowingContent={isInfoPopoverOpen}
          onShowContent={handleShowInfoPopover}
          onHideContent={handleHideInfoPopover}
          on="click"
          placement="top"
          shouldContainFocus
          shouldReturnFocus
          shouldCloseOnDocumentClick={true}
          screenReaderLabel={I18n.t('Why it matters')}
          renderTrigger={() => (
            // the div wrapper is needed to pass aria-expanded
            <div>
              <CondensedButton
                onClick={handleShowInfoPopover}
                renderIcon={<IconInfoLine />}
                aria-label={I18n.t('Tooltip issues information')}
              />
            </div>
          )}
        >
          <Flex direction="column" width="18rem" padding="medium" gap="medium">
            <CloseButton
              placement="end"
              offset="small"
              onClick={handleHideInfoPopover}
              screenReaderLabel={I18n.t('Close')}
            />
            <Heading level="h3" margin="0">
              {I18n.t('Why it matters')}
            </Heading>
            <Flex.Item>
              <Text size="medium" lineHeight="default">
                {currentIssue?.rule.why()}
              </Text>
            </Flex.Item>
            {currentIssue?.rule.link && (
              <Flex.Item>
                <Text size="medium">
                  <Link
                    href={currentIssue.rule.link}
                    target="_blank"
                    rel="noopener noreferrer"
                    iconPlacement="end"
                    renderIcon={<IconExternalLinkLine size="x-small" />}
                  >
                    {currentIssue.rule.linkText?.()}
                    <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
                  </Link>
                </Text>
              </Flex.Item>
            )}
          </Flex>
        </Popover>
      </Flex>

      <Text variant="content">{currentIssue?.rule.message()}</Text>
    </View>
  )
}
