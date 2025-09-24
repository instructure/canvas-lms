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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Popover} from '@instructure/ui-popover'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {IconAiColoredSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('rubrics')

const AiUsageButton = () => {
  const [isShowingContent, setIsShowingContent] = useState(false)

  return (
    <Popover
      renderTrigger={
        <Button
          color="ai-secondary"
          renderIcon={<IconAiColoredSolid />}
          size="small"
          themeOverride={{
            borderRadius: '999rem',
          }}
        >
          {I18n.t('AI Assisted')}
        </Button>
      }
      on="click"
      isShowingContent={isShowingContent}
      onShowContent={() => {
        setIsShowingContent(true)
      }}
      onHideContent={() => {
        setIsShowingContent(false)
      }}
      shouldContainFocus
      shouldReturnFocus
      shouldCloseOnDocumentClick
      placement="bottom center"
      withArrow={true}
    >
      <Flex direction="column" width={320} padding="medium" justifyItems="space-between">
        <Flex.Item padding="0 0 medium 0">
          <Flex>
            <Flex.Item>
              <Heading variant="label" color="ai" margin="0">
                <IconAiColoredSolid />
                &nbsp; IgniteAI
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                placement="end"
                offset="small"
                onClick={() => setIsShowingContent(false)}
                screenReaderLabel={I18n.t('Close')}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item padding="0 0 x-small 0">
          <Text>
            {I18n.t(
              'To support more fair and consistent grading, AI was used to assist in the grading process. All final grades are determined by your teacher.',
            )}
          </Text>
        </Flex.Item>
      </Flex>
    </Popover>
  )
}

export default AiUsageButton
