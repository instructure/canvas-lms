/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

export type RowHeaderProps = ViewProps & {
  children?: React.ReactNode
  isSticky?: boolean
  isStacked?: boolean
  'data-cell-id'?: string
}

export const RowHeader = ({
  children,
  isSticky,
  isStacked,
  'data-cell-id': dataCellId,
  ...props
}: RowHeaderProps) => {
  return (
    <View
      borderWidth="0 0 small 0"
      overflowX="auto"
      as={isStacked ? 'div' : 'th'}
      role={isStacked ? 'rowheader' : undefined}
      scope="row"
      position={isSticky ? 'sticky' : 'static'}
      stacking="topmost"
      insetInlineStart={isSticky ? '0' : undefined}
      background={isSticky && !props.background ? 'primary' : props.background}
      focusPosition="inset"
      data-cell-id={dataCellId}
      {...props}
    >
      {children}
    </View>
  )
}
