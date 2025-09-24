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

import './base-block-layout.css'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {PropsWithChildren, ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

export const BaseBlockLayout = (
  props: PropsWithChildren<{
    title: string
    menu: ReactNode
    addButton: ReactNode
    topA11yActionMenu: ReactNode
    bottomA11yActionMenu: ReactNode
    nodeId: string
  }>,
) => {
  return (
    <div data-bce-node-id={props.nodeId} className="base-block-layout">
      <Flex direction="column" padding="paddingCardLarge">
        <Flex justifyItems="space-between" margin="0 0 mediumSmall 0">
          <Flex data-header>
            <ScreenReaderContent>{I18n.t('Block type')}</ScreenReaderContent>
            <Tag text={props.title} size="medium" data-testid="block-type-label" />
          </Flex>
          <Flex data-testid="block-menu">{props.menu}</Flex>
        </Flex>
        <Flex data-focus-reveal-parent margin="0 0 mediumSmall 0">
          {props.topA11yActionMenu}
        </Flex>
        <Flex direction="column" gap="mediumSmall">
          <Flex direction="column" gap="small" width={'100%'}>
            {props.children}
          </Flex>
          <Flex width={'100%'} justifyItems="end" gap="small">
            {props.bottomA11yActionMenu}
          </Flex>
        </Flex>
      </Flex>
      {props.addButton}
    </div>
  )
}
