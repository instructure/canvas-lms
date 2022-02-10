/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {CloseButton} from '@instructure/ui-buttons'

import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'

import formatMessage from '../../../../format-message'
import {getTrayHeight} from '../../shared/trayUtils'
import {CreateButtonForm} from './CreateButtonForm'

export function ButtonsTray({editor, onUnmount, editing}) {
  const [isOpen, setIsOpen] = useState(true)

  const title = formatMessage('Buttons and Icons')

  return (
    <Tray
      data-mce-component
      label={title}
      onDismiss={() => setIsOpen(false)}
      onExited={onUnmount}
      open={isOpen}
      placement="end"
      shouldContainFocus
      shouldReturnFocus
      size="regular"
    >
      <Flex direction="column" height={getTrayHeight()}>
        <Flex.Item as="header" padding="medium">
          <Flex direction="row">
            <Flex.Item grow shrink>
              <Heading as="h2">{title}</Heading>
            </Flex.Item>

            <Flex.Item>
              <CloseButton placement="static" variant="icon" onClick={() => setIsOpen(false)}>
                {formatMessage('Close')}
              </CloseButton>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item as="slot" padding="small">
          <CreateButtonForm editor={editor} editing={editing} onClose={() => setIsOpen(false)} />
        </Flex.Item>
      </Flex>
    </Tray>
  )
}
