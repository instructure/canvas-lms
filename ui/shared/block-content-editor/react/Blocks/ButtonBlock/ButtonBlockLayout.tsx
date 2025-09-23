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

import {Flex} from '@instructure/ui-flex'
import {ButtonBlockLayoutProps} from './types'

const alignmentMap = {
  left: 'start',
  center: 'center',
  right: 'end',
} as const

export const ButtonBlockLayout = ({
  buttons,
  alignment,
  layout,
  isFullWidth,
  dataTestId,
  focusHandler,
  ButtonComponent,
}: ButtonBlockLayoutProps) => {
  const flexDirection = layout === 'vertical' ? 'column' : 'row'
  const justifyItems = !isFullWidth && layout === 'horizontal' ? alignmentMap[alignment] : undefined
  const alignItems = !isFullWidth && layout === 'vertical' ? alignmentMap[alignment] : undefined

  return (
    <Flex
      data-testid={dataTestId}
      direction={flexDirection}
      justifyItems={justifyItems}
      alignItems={alignItems}
      width="100%"
      wrap="wrap"
      gap="small"
    >
      {buttons.map((button, i) => (
        <Flex.Item key={button.id} shouldGrow={isFullWidth} overflowX="visible" overflowY="visible">
          <ButtonComponent
            id={button.id}
            text={button.text}
            url={button.url}
            linkOpenMode={button.linkOpenMode}
            primaryColor={button.primaryColor}
            secondaryColor={button.secondaryColor}
            style={button.style}
            isFullWidth={isFullWidth}
            focusHandler={i === 0 ? focusHandler : undefined}
          />
        </Flex.Item>
      ))}
    </Flex>
  )
}
