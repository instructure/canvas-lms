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

import {useScope as createI18nScope} from '@canvas/i18n'
import {useState} from 'react'
import {Popover} from '@instructure/ui-popover'
import {Flex} from '@instructure/ui-flex'
import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {IconExternalLinkLine, IconQuestionLine, IconWarningSolid} from '@instructure/ui-icons'
import {AccessibilityIssue} from '../../types'
import {Link} from '@instructure/ui-link'
import canvas from '@instructure/ui-themes'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('accessibility_checker')

interface WhyMattersPopoverProps {
  issue: AccessibilityIssue
}

const WhyMattersPopover = ({issue}: WhyMattersPopoverProps) => {
  const [isShowingContent, setIsShowingContent] = useState(false)
  const why = typeof issue.why === 'string' ? [issue.why] : issue.why

  return (
    <Popover
      placement="bottom"
      isShowingContent={isShowingContent}
      shouldContainFocus
      shouldCloseOnDocumentClick={true}
      onHideContent={() => setIsShowingContent(false)}
      on="click"
      screenReaderLabel={I18n.t('Why it matters')}
      renderTrigger={() => (
        <IconButton
          onClick={() => setIsShowingContent(!isShowingContent)}
          screenReaderLabel={I18n.t('Why it matters')}
          renderIcon={() => <IconQuestionLine size="x-small" />}
          data-testid="why-it-matters-button"
          withBackground={false}
          withBorder={false}
          size="small"
          shape="circle"
        />
      )}
    >
      <Flex direction="column" padding="medium" width="22rem" gap="mediumSmall">
        <Flex.Item>
          <Flex justifyItems="space-between" alignItems="center">
            <Flex.Item>
              <Heading level="h3" margin="none">
                {I18n.t('Why it matters')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                margin="x-small"
                screenReaderLabel={I18n.t('Close')}
                onClick={() => setIsShowingContent(false)}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        {why.map((paragraph, index) => (
          <Flex.Item key={index} margin="0 0 x-small 0">
            <Text variant="content">{paragraph}</Text>
          </Flex.Item>
        ))}
        {issue.issueUrl && (
          <Flex.Item>
            <Flex direction="column">
              <Flex.Item>
                <Heading level="h4" margin="none">
                  <IconWarningSolid fontSize={canvas.typography.legend} color="warning" />{' '}
                  <Text color="warning" weight="bold" size="legend">
                    {I18n.t('IMPORTANT')}
                  </Text>
                </Heading>
              </Flex.Item>
              <Flex.Item>
                <Text variant="contentSmall">
                  {I18n.t('This is a')}{' '}
                  <Link
                    href={issue.issueUrl}
                    variant="standalone"
                    target="_blank"
                    rel="noopener noreferrer"
                    iconPlacement="end"
                    renderIcon={<IconExternalLinkLine size="x-small" />}
                  >
                    {I18n.t('WCAG requirement')}{' '}
                    <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
                  </Link>{' '}
                  {I18n.t(
                    'and part of accessibility standards that educational content must meet to be\n' +
                      'inclusive for all learners, including those using screen readers.',
                  )}
                </Text>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        )}
      </Flex>
    </Popover>
  )
}

export default WhyMattersPopover
