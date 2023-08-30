/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React from 'react'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import formatMessage from 'format-message'

import type {TrayProps} from '@instructure/ui-tray'

interface ExternalToolDialogTrayProps {
  open: TrayProps['open']
  label: TrayProps['label']
  mountNode: TrayProps['mountNode']
  onOpen?: TrayProps['onOpen']
  onClose?: TrayProps['onClose']
  onCloseButton?: () => void
  name: string
  children: TrayProps['children']
}

export function ExternalToolDialogTray(props: ExternalToolDialogTrayProps) {
  const {label, onCloseButton, name, children, ...extraProps} = props

  const padding = '0'

  return (
    <Tray label={label} onDismiss={onCloseButton} placement="end" size="regular" {...extraProps}>
      {/* This needs to be a View to interpret the outer padding prop, and it needs to be positioned
          so it can properly apply padding and allow the nested elements to have relative widths. */}
      <View
        as="div"
        padding={padding}
        position="absolute"
        insetBlockStart="0"
        insetBlockEnd="0"
        insetInlineStart="0"
        insetInlineEnd="0"
      >
        {/* We're using divs for the reasons stated above. The outer div should take up the full
            size of the parent View so that the inner content div can flex-grow to fill up the
            remaining vertical space below the header. The content div also provides a positioning
            context so this component's children can position themselves relative to the content
            section rather than the whole Tray */}
        <div style={{display: 'flex', flexDirection: 'column', width: '100%', height: '100%'}}>
          <Flex as="div" padding="small">
            <Flex.Item shouldGrow={true}>
              <Heading>{name}</Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                onClick={onCloseButton}
                size="small"
                screenReaderLabel={formatMessage('Close')}
              />
            </Flex.Item>
          </Flex>

          <div style={{position: 'relative', flex: 1}}>
            <View as="div" width="100%" height="100%">
              {children}
            </View>
          </div>
        </div>
      </View>
    </Tray>
  )
}
