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
import {act} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {WidgetConfigProvider, useWidgetConfig} from '../useWidgetConfig'
import {WidgetDashboardEditProvider} from '../useWidgetDashboardEdit'
import type {WidgetConfig} from '../../types'

const wrapper = ({children}: {children: React.ReactNode}) => (
  <WidgetDashboardEditProvider>
    <WidgetConfigProvider>{children}</WidgetConfigProvider>
  </WidgetDashboardEditProvider>
)

describe('useWidgetConfig', () => {
  it('provides initial config', () => {
    const {result} = renderHook(() => useWidgetConfig(), {wrapper})
    expect(result.current.config.widgets).toHaveLength(4)
  })

  describe('moveWidget', () => {
    it('moves widget left from column 2 to column 1', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 2)!

      act(() => {
        result.current.moveWidget(widget.id, 'move-left')
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(movedWidget.position.col).toBe(1)
    })

    it('moves widget right from column 1 to column 2', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)!

      act(() => {
        result.current.moveWidget(widget.id, 'move-right')
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(movedWidget.position.col).toBe(2)
    })

    it('does not move widget left when already in column 1', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)!
      const originalRow = widget.position.row

      act(() => {
        result.current.moveWidget(widget.id, 'move-left')
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(movedWidget.position.col).toBe(1)
      expect(movedWidget.position.row).toBe(originalRow)
    })

    it('does not move widget right when already in column 2', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 2)!
      const originalRow = widget.position.row

      act(() => {
        result.current.moveWidget(widget.id, 'move-right')
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(movedWidget.position.col).toBe(2)
      expect(movedWidget.position.row).toBe(originalRow)
    })

    it('moves widget left top from column 2 to column 1 at row 1', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 2)!

      act(() => {
        result.current.moveWidget(widget.id, 'move-left-top')
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(movedWidget.position.col).toBe(1)
      expect(movedWidget.position.row).toBe(1)
    })

    it('moves widget right top from column 1 to column 2 at row 1', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)!

      act(() => {
        result.current.moveWidget(widget.id, 'move-right-top')
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(movedWidget.position.col).toBe(2)
      expect(movedWidget.position.row).toBe(1)
    })

    it('moves widget up in same column', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const col1Widgets = result.current.config.widgets
        .filter(w => w.position.col === 1)
        .sort((a, b) => a.position.row - b.position.row)

      if (col1Widgets.length > 1) {
        const secondWidget = col1Widgets[1]
        const firstWidget = col1Widgets[0]

        act(() => {
          result.current.moveWidget(secondWidget.id, 'move-up')
        })

        const movedWidget = result.current.config.widgets.find(w => w.id === secondWidget.id)!
        const otherWidget = result.current.config.widgets.find(w => w.id === firstWidget.id)!

        expect(movedWidget.position.row).toBeLessThan(otherWidget.position.row)
      }
    })

    it('moves widget down in same column', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const col1Widgets = result.current.config.widgets
        .filter(w => w.position.col === 1)
        .sort((a, b) => a.position.row - b.position.row)

      if (col1Widgets.length > 1) {
        const firstWidget = col1Widgets[0]
        const secondWidget = col1Widgets[1]

        act(() => {
          result.current.moveWidget(firstWidget.id, 'move-down')
        })

        const movedWidget = result.current.config.widgets.find(w => w.id === firstWidget.id)!
        const otherWidget = result.current.config.widgets.find(w => w.id === secondWidget.id)!

        expect(movedWidget.position.row).toBeGreaterThan(otherWidget.position.row)
      }
    })

    it('moves widget to top of column', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const col1Widgets = result.current.config.widgets
        .filter(w => w.position.col === 1)
        .sort((a, b) => a.position.row - b.position.row)

      if (col1Widgets.length > 1) {
        const lastWidget = col1Widgets[col1Widgets.length - 1]

        act(() => {
          result.current.moveWidget(lastWidget.id, 'move-to-top')
        })

        const movedWidget = result.current.config.widgets.find(w => w.id === lastWidget.id)!
        expect(movedWidget.position.row).toBe(1)
      }
    })

    it('moves widget to bottom of column', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const col1Widgets = result.current.config.widgets
        .filter(w => w.position.col === 1)
        .sort((a, b) => a.position.row - b.position.row)

      if (col1Widgets.length > 1) {
        const firstWidget = col1Widgets[0]
        const maxRow = Math.max(...col1Widgets.map(w => w.position.row))

        act(() => {
          result.current.moveWidget(firstWidget.id, 'move-to-bottom')
        })

        const movedWidget = result.current.config.widgets.find(w => w.id === firstWidget.id)!
        expect(movedWidget.position.row).toBe(maxRow)
      }
    })

    it('recalculates relative positions after move', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)!

      act(() => {
        result.current.moveWidget(widget.id, 'move-right')
      })

      const relativePositions = result.current.config.widgets.map(w => w.position.relative)
      const uniqueRelatives = new Set(relativePositions)

      expect(uniqueRelatives.size).toBe(result.current.config.widgets.length)
    })

    it('normalizes row numbers after move', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)!

      act(() => {
        result.current.moveWidget(widget.id, 'move-to-bottom')
      })

      const col1Widgets = result.current.config.widgets
        .filter(w => w.position.col === 1)
        .sort((a, b) => a.position.row - b.position.row)

      col1Widgets.forEach((w, index) => {
        expect(w.position.row).toBe(index + 1)
      })
    })
  })

  describe('resetConfig', () => {
    it('resets config to default', () => {
      const {result} = renderHook(() => useWidgetConfig(), {wrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)!

      act(() => {
        result.current.moveWidget(widget.id, 'move-right')
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(movedWidget.position.col).toBe(2)

      act(() => {
        result.current.resetConfig()
      })

      const resetWidget = result.current.config.widgets.find(w => w.id === widget.id)!
      expect(resetWidget.position.col).toBe(1)
    })
  })
})
