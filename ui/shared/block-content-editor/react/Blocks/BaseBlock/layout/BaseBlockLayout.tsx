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
import {PropsWithChildren, ReactNode} from 'react'

export const BaseBlockLayout = (
  props: PropsWithChildren<{
    title: string
    menu: ReactNode
    actionButtons: ReactNode
    addButton: ReactNode
    a11yEditButton: ReactNode
    nodeId: string
  }>,
) => {
  return (
    <div data-bce-node-id={props.nodeId} className="base-block-layout">
      <Flex direction="column" padding="paddingCardLarge">
        {props.a11yEditButton && (
          <Flex data-focus-reveal-parent margin="0 0 mediumSmall 0">
            {props.a11yEditButton}
          </Flex>
        )}
        <Flex direction="column" gap="mediumSmall">
          <Flex justifyItems="space-between">
            <Flex data-header>
              <Tag text={props.title} size="medium" data-testid="block-type-label" />
            </Flex>
            <Flex>{props.menu}</Flex>
          </Flex>
          <Flex direction="column" gap="small" width={'100%'}>
            {props.children}
          </Flex>
          <Flex width={'100%'} justifyItems="end" gap="small">
            {props.actionButtons}
          </Flex>
        </Flex>
      </Flex>
      {props.addButton}
    </div>
  )
}
