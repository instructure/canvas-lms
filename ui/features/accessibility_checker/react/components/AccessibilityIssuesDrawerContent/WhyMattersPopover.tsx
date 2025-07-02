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
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {IconQuestionLine, IconWarningSolid} from '@instructure/ui-icons'
import {AccessibilityIssue} from '../../types'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('accessibility_checker')

interface WhyMattersPopoverProps {
  issue: AccessibilityIssue
}

const WhyMattersPopover = ({issue}: WhyMattersPopoverProps) => {
  const [isShowingContent, setIsShowingContent] = useState(false)

  return (
    <Popover
      placement="bottom"
      isShowingContent={isShowingContent}
      shouldContainFocus
      shouldCloseOnDocumentClick={true}
      renderTrigger={() => (
        <IconQuestionLine
          onClick={() => setIsShowingContent(true)}
          description={'Open accessibility explanation'}
          style={{cursor: 'pointer'}}
          focusable={true}
          size="x-small"
        />
      )}
    >
      <Flex direction="column" padding="medium" width="22rem" gap="small">
        <Flex.Item>
          <Flex justifyItems="space-between" alignItems="center" margin="0 0 small 0">
            <Flex.Item>
              <Heading level="h3" margin="none">
                {I18n.t('Why it matters')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                margin="x-small"
                screenReaderLabel="close tooltip"
                onClick={() => setIsShowingContent(false)}
              >
                {I18n.t('Close')}
              </CloseButton>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <Text variant="content">{issue.why}</Text>
        </Flex.Item>
        <Flex.Item>
          <Text color="danger" weight="bold">
            <IconWarningSolid /> {I18n.t('IMPORTANT')}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Text variant="contentSmall">
            {I18n.t('This is a')} <Link href={issue.issueUrl}>{I18n.t('WCAG requirement')}</Link>{' '}
            {I18n.t(
              'and part of accessibility standards that educational content must meet to be\n' +
                'inclusive for all learners, including those using screen readers.',
            )}
          </Text>
        </Flex.Item>
      </Flex>
    </Popover>
  )
}

export default WhyMattersPopover
