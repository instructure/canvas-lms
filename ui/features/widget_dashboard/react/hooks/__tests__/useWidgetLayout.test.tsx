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

import {act} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import React from 'react'
import {WidgetLayoutProvider, useWidgetLayout} from '../useWidgetLayout'
import {WidgetDashboardEditProvider} from '../useWidgetDashboardEdit'

const createWrapper = ({children}: {children: React.ReactNode}) => {
  return (
    <WidgetDashboardEditProvider>
      <WidgetLayoutProvider>{children}</WidgetLayoutProvider>
    </WidgetDashboardEditProvider>
  )
}

describe('useWidgetLayout', () => {
  describe('removeWidget', () => {
    it('removes widget from config', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const initialWidgetCount = result.current.config.widgets.length
      const widgetToRemove = result.current.config.widgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      expect(result.current.config.widgets).toHaveLength(initialWidgetCount - 1)
      expect(result.current.config.widgets.find(w => w.id === widgetToRemove.id)).toBeUndefined()
    })

    it('recalculates positions after removing widget', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widgetToRemove = result.current.config.widgets[0]
      const column = widgetToRemove.position.col

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      const remainingWidgetsInColumn = result.current.config.widgets.filter(
        w => w.position.col === column,
      )

      remainingWidgetsInColumn.forEach((widget, index) => {
        expect(widget.position.row).toBe(index + 1)
      })
    })

    it('recalculates relative positions after removing widget', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widgetToRemove = result.current.config.widgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      result.current.config.widgets.forEach((widget, index) => {
        expect(widget.position.relative).toBe(index + 1)
      })
    })

    it('handles removing non-existent widget gracefully', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const initialWidgetCount = result.current.config.widgets.length

      act(() => {
        result.current.removeWidget('non-existent-widget-id')
      })

      expect(result.current.config.widgets).toHaveLength(initialWidgetCount)
    })

    it('can remove all widgets', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widgetIds = result.current.config.widgets.map(w => w.id)

      act(() => {
        widgetIds.forEach(id => {
          result.current.removeWidget(id)
        })
      })

      expect(result.current.config.widgets).toHaveLength(0)
    })

    it('removes widget from left column and normalizes remaining widgets', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const leftColumnWidgets = result.current.config.widgets.filter(w => w.position.col === 1)
      const widgetToRemove = leftColumnWidgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      const remainingLeftColumnWidgets = result.current.config.widgets.filter(
        w => w.position.col === 1,
      )
      expect(remainingLeftColumnWidgets).toHaveLength(leftColumnWidgets.length - 1)
    })

    it('removes widget from right column and normalizes remaining widgets', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const rightColumnWidgets = result.current.config.widgets.filter(w => w.position.col === 2)
      if (rightColumnWidgets.length === 0) {
        return
      }

      const widgetToRemove = rightColumnWidgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      const remainingRightColumnWidgets = result.current.config.widgets.filter(
        w => w.position.col === 2,
      )
      expect(remainingRightColumnWidgets).toHaveLength(rightColumnWidgets.length - 1)
    })
  })
})
