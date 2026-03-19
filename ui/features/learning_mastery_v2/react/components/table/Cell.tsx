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

import {View, ViewProps} from '@instructure/ui-view'
import React from 'react'

export type CellProps = Omit<ViewProps, 'children'> & {
  id?: string
  width?: number | string
  boxShadow?: string
  isSticky?: boolean
  isStacked?: boolean
  header?: string | (() => React.ReactNode)
  children?: React.ReactNode | ((focused: boolean) => React.ReactNode)
}

export const Cell: React.FC<CellProps> = ({
  id,
  children,
  width,
  boxShadow,
  isSticky,
  isStacked,
  header,
  ...props
}: CellProps) => {
  const [focus, setFocus] = React.useState(false)
  const cellRef = React.useRef<HTMLElement | null>(null)

  const handleBlur = (event: React.FocusEvent) => {
    // Check if focus is moving to a descendant of this cell
    const relatedTarget = event.relatedTarget as Node
    if (relatedTarget && cellRef.current?.contains(relatedTarget)) {
      // Focus is still within the cell, don't hide
      return
    }
    setFocus(false)
  }

  return (
    <View
      id={id}
      width={width}
      height="inherit"
      borderWidth="0 0 small 0"
      overflowX="auto"
      as={isStacked ? 'div' : 'td'}
      role={isStacked ? 'cell' : undefined}
      position={isSticky ? 'sticky' : 'static'}
      stacking="above"
      insetInlineStart={isSticky ? '0' : undefined}
      background={isSticky && !props.background ? 'primary' : props.background}
      focusPosition="inset"
      elementRef={el => {
        if (el instanceof HTMLElement) {
          cellRef.current = el
        }
      }}
      onFocus={() => setFocus(true)}
      onBlur={handleBlur}
      themeOverride={(_componentTheme, currentTheme) => ({
        shadowAbove: boxShadow ?? `2px 0 0 0 ${currentTheme.colors.contrasts.grey1214}`,
      })}
      {...props}
    >
      {header ? (typeof header === 'function' ? header() : header) : null}
      {typeof children === 'function' ? children(focus) : children}
    </View>
  )
}
