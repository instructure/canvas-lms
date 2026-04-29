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

import {View} from '@instructure/ui-view'

interface GridProps {
  templateColumns?: string
  templateAreas: string
  rowGap?: string
  columnGap?: string
  alignItems?: string
  children: React.ReactNode
}

/**
 * Grid container component for CSS Grid layouts with named template areas
 */
export const Grid = ({
  templateColumns = '1fr',
  templateAreas,
  rowGap = '0.5rem',
  columnGap = '0.5rem',
  alignItems,
  children,
}: GridProps) => (
  <View
    as="div"
    elementRef={(el: Element | null) => {
      if (el instanceof HTMLElement) {
        el.style.display = 'grid'
        el.style.gridTemplateColumns = templateColumns
        el.style.gridTemplateAreas = templateAreas
        el.style.rowGap = rowGap
        el.style.columnGap = columnGap
        if (alignItems) {
          el.style.alignItems = alignItems
        }
      }
    }}
  >
    {children}
  </View>
)

interface GridAreaProps {
  area: string
  children: React.ReactNode
  additionalStyles?: Partial<CSSStyleDeclaration>
}

/**
 * GridArea component that wraps children and assigns them to a named grid area
 */
export const GridArea = ({area, children, additionalStyles}: GridAreaProps) => (
  <View
    as="div"
    elementRef={(el: Element | null) => {
      if (el instanceof HTMLElement) {
        el.style.gridArea = area
        if (additionalStyles) {
          Object.assign(el.style, additionalStyles)
        }
      }
    }}
  >
    {children}
  </View>
)
