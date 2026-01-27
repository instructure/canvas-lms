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

import React, {Children, isValidElement, useContext} from 'react'
import {View, ViewProps} from '@instructure/ui-view'
import {TableContext} from '@instructure/ui-table'
import {safeCloneElement} from '@instructure/ui-react-utils'

export type RowProps = ViewProps & {
  children: React.ReactNode
  setRef?: (ref: HTMLElement | null) => void
}

export const Row: React.FC<RowProps> = ({children, setRef}) => {
  const context = useContext(TableContext)
  const isStacked = context.isStacked
  const headers = context.headers

  return (
    <View
      as={isStacked ? 'div' : 'tr'}
      role={isStacked ? 'row' : undefined}
      elementRef={setRef}
      // trick to ensure full height div in cell
      height="1px"
    >
      {Children.toArray(children)
        .filter(Boolean)
        .map((child, index) => {
          if (isValidElement(child)) {
            return safeCloneElement(child, {
              key: child.props.name,
              isStacked,
              header: headers && headers[index],
            })
          }
          return child
        })}
    </View>
  )
}
