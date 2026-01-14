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
import React from 'react'
import {View, ViewProps} from '@instructure/ui-view'
import {COLUMN_WIDTH, CELL_HEIGHT, COLUMN_PADDING} from '../../utils/constants'
import {Flex} from '@instructure/ui-flex'

export interface CellProps extends ViewProps {
  children: React.ReactNode
}

export const Cell: React.FC<CellProps> = ({children, ...props}) => {
  return (
    <Flex.Item size={`${COLUMN_WIDTH + COLUMN_PADDING}px`}>
      <View
        role="gridcell"
        as="div"
        height={CELL_HEIGHT}
        borderWidth="0 0 small 0"
        width={COLUMN_WIDTH}
        overflowX="auto"
        {...props}
      >
        {children}
      </View>
    </Flex.Item>
  )
}
