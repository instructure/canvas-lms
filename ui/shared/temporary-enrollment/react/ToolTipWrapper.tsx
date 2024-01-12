/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {type ReactNode} from 'react'
import {View} from '@instructure/ui-view'

interface Props {
  width?: string
  positionTop?: string
  positionLeft?: string
  children: ReactNode
}

const ICON_BUTTON_WIDTH_SMALL: string = '1.75rem'

const ToolTipWrapper = ({
  width = ICON_BUTTON_WIDTH_SMALL,
  positionTop = '0',
  positionLeft = '0',
  children,
}: Props): JSX.Element => {
  return (
    <View as="div" position="relative" width={width}>
      <View
        position="absolute"
        insetBlockStart={positionTop}
        insetInlineStart={positionLeft}
        width={width}
      >
        {children}
      </View>
    </View>
  )
}

export default ToolTipWrapper
