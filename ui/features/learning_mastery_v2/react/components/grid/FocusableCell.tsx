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
import {Cell, CellProps} from './Cell'
import {Focusable} from '@instructure/ui-focusable'

export interface WithFocusProps {
  focused?: boolean
}

interface FocusableWrapperProps extends CellProps {
  focused?: boolean
  children: React.ReactNode
}

const FocusableWrapper = React.forwardRef<Element, FocusableWrapperProps>(
  ({children, focused, ...props}, ref) => {
    const elementRef = React.useRef<Element | null>(null)

    const handleRef = React.useCallback(
      (el: Element | null) => {
        elementRef.current = el

        if (!ref) return

        if (typeof ref === 'function') {
          ref(el)
        } else {
          ref.current = el
        }
      },
      [ref],
    )

    return (
      <Cell
        {...props}
        withFocusOutline={focused}
        focusPosition="inset"
        tabIndex={0}
        elementRef={handleRef}
      >
        {children}
      </Cell>
    )
  },
)

FocusableWrapper.displayName = 'FocusableWrapper'

export interface FocusableCellProps extends Omit<CellProps, 'children'> {
  children: React.ReactNode | ((focused: boolean) => React.ReactNode)
}

export const FocusableCell: React.FC<FocusableCellProps> = ({children, ...props}) => {
  return (
    <Focusable>
      {({focused, attachRef}) => (
        <FocusableWrapper {...props} focused={focused} ref={attachRef}>
          {typeof children === 'function' ? children(focused) : children}
        </FocusableWrapper>
      )}
    </Focusable>
  )
}
