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

import {ReactNode} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Tray, type TrayProps} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {getTrayHeight} from '../../../utils/trayUtils'
import {CloseButton} from '@instructure/ui-buttons'

type TrayWrapperProps = TrayProps & {
  header?: ReactNode
  footer?: ReactNode
  closeLabel: string
}

const TrayWrapper = ({
  header,
  children,
  footer,
  onClose,
  closeLabel,
  ...trayProps
}: TrayWrapperProps) => {
  return (
    <Tray
      placement="end"
      shouldCloseOnDocumentClick={true}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      {...trayProps}
    >
      <Flex as="div" height={getTrayHeight()} direction="column">
        <Flex.Item as="header" padding="medium">
          <Flex direction="row">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              {header}
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                screenReaderLabel={closeLabel}
                // Needed to use any here to call onDismiss
                onClick={e => trayProps.onDismiss?.(e as any)}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={false} padding="small">
          {children}
        </Flex.Item>
        <Flex.Item as="footer">
          <View
            as="div"
            padding="small"
            textAlign="end"
            background="secondary"
            borderWidth="small none none none"
          >
            {footer}
          </View>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

export default TrayWrapper
