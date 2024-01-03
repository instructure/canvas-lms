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

import React from 'react'
import RoleMismatchToolTip from './RoleMismatchToolTip'
import {View} from '@instructure/ui-view'
import {ENROLLMENT_TREE_ICON_OFFSET} from './types'

interface Props {
  width?: string
  positionTop?: string
  positionLeft?: string
}

const ICON_BUTTON_WIDTH_SMALL: string = '1.75rem'

const RoleMismatchToolTipWrapper = ({
  width = ICON_BUTTON_WIDTH_SMALL,
  positionTop = ENROLLMENT_TREE_ICON_OFFSET,
  positionLeft = '0',
}: Props): JSX.Element => {
  return (
    <View as="div" position="relative" width={width}>
      <View
        position="absolute"
        insetBlockStart={positionTop}
        insetInlineStart={positionLeft}
        width={width}
      >
        <RoleMismatchToolTip />
      </View>
    </View>
  )
}

export default RoleMismatchToolTipWrapper
