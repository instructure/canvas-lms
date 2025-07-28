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

import React, {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Popover} from '@instructure/ui-popover'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconInfoLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('files_v2')

const lockedFilesText = I18n.t(
  "You can't *delete, edit permissions, manage usage rights, or move* locked files.",
  {
    wrappers: [`<strong>$1</strong>`],
  },
)

const lockedFoldersText = I18n.t(
  "You can't *delete, edit permissions, manage usage rights, or move* locked folders.",
  {
    wrappers: [`<strong>$1</strong>`],
  },
)

export interface DisabledActionsInfoButtonProps {
  size: 'small' | 'medium' | 'large'
}

export function DisabledActionsInfoButton({size}: DisabledActionsInfoButtonProps) {
  const [open, setOpen] = useState(false)
  const isDesktop = size === 'large'

  return (
    <Flex.Item>
      <Popover
        renderTrigger={
          <Button
            themeOverride={{borderStyle: 'none'}}
            renderIcon={<IconInfoLine />}
            color="primary"
            withBackground={false}
            data-testid="disabled-actions-info-button"
          >
            {isDesktop ? I18n.t('Disabled actions') : ''}
            <ScreenReaderContent>
              {isDesktop ? I18n.t('info') : I18n.t('Disabled actions info')}
            </ScreenReaderContent>
          </Button>
        }
        isShowingContent={open}
        onShowContent={_e => {
          setOpen(true)
        }}
        onHideContent={_e => {
          setOpen(false)
        }}
        on="click"
        screenReaderLabel={I18n.t('Disabled Actions Info')}
        shouldContainFocus
        shouldReturnFocus
        shouldCloseOnDocumentClick
        constrain="scroll-parent"
        placement="bottom start"
      >
        <Flex padding="medium" direction="column" width={isDesktop ? '375px' : '260px'} gap="small">
          <CloseButton
            placement="end"
            offset="small"
            onClick={() => setOpen(false)}
            screenReaderLabel="Close"
          />
          <Flex.Item padding="0 0 medium 0">
            <Heading
              level="h3"
              as="h2"
              color="secondary"
              themeOverride={{
                h3FontWeight: 500,
              }}
            >
              {I18n.t('Disabled actions')}
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <Text>
              {I18n.t(
                'You can access limited functionalities based on what items are in the selection.',
              )}
            </Text>
          </Flex.Item>
          <>
            <Flex.Item>
              <Heading
                border="top"
                themeOverride={{
                  borderPadding: '1rem',
                }}
                level="h4"
                as="h3"
              >
                {I18n.t('Locked files')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <Text dangerouslySetInnerHTML={{__html: lockedFilesText}} />
            </Flex.Item>

            <Flex.Item className="disabled-actions-heading" padding="small 0 0 0">
              <Heading
                border="top"
                themeOverride={{
                  borderPadding: '1rem',
                }}
                level="h4"
                as="h3"
              >
                {I18n.t('Folders containing locked content')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <Text dangerouslySetInnerHTML={{__html: lockedFoldersText}} />
            </Flex.Item>
          </>
        </Flex>
      </Popover>
    </Flex.Item>
  )
}
