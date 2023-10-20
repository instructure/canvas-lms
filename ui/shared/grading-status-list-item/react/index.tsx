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

type GradingStatusListItemProps = {
  children: React.ReactNode
  cursor?: string
  backgroundColor: string
  borderColor?: string
  borderStyle?: string
  borderWidth?: string
  display?: string
  setElementRef?: (ref: HTMLDivElement) => void
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
      backgroundColor="primary"
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
      theme={{backgroundPrimary: backgroundColor, borderStyle: borderStyle ?? 'solid'}}
    >
      {children}
    </View>
  )
}
