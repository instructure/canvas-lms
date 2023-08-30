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
import {View} from '@instructure/ui-view'
import type {BorderWidth} from '@instructure/emotion'
import type {Cursor} from '@instructure/ui-prop-types'

type GradingStatusListItemProps = {
  children: React.ReactNode
  cursor?: Cursor
  backgroundColor: string
  borderColor?:
    | 'transparent'
    | 'primary'
    | 'secondary'
    | 'brand'
    | 'info'
    | 'success'
    | 'warning'
    | 'alert'
    | 'danger'
  borderStyle?: string
  borderWidth?: BorderWidth
  display?: 'auto' | 'inline' | 'block' | 'inline-block' | 'flex' | 'inline-flex'
  setElementRef?: (ref: Element | null) => void
}
export const GradingStatusListItem = ({
  backgroundColor,
  borderColor,
  borderStyle,
  borderWidth,
  children,
  cursor,
  display,
  setElementRef,
}: GradingStatusListItemProps) => {
  return (
    <View
      as="div"
      borderWidth={borderWidth ?? 'medium'}
      borderColor={borderColor ?? 'primary'}
      borderRadius="large"
      cursor={cursor}
      padding="x-small"
      background="primary"
      height="3rem"
      width="16.25rem"
      display={display ?? 'block'}
      elementRef={setElementRef}
      themeOverride={{backgroundPrimary: backgroundColor, borderStyle: borderStyle ?? 'solid'}}
    >
      {children}
    </View>
  )
}
