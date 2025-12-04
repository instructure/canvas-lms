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

import React, {createContext, useContext, useState, useCallback} from 'react'
import type {WidgetConfig, Widget} from '../types'
import {DEFAULT_WIDGET_CONFIG, LEFT_COLUMN, RIGHT_COLUMN} from '../constants'
import {useWidgetDashboardEdit} from './useWidgetDashboardEdit'

export type MoveAction =
  | 'move-left'
  | 'move-right'
  | 'move-left-top'
  | 'move-right-top'
  | 'move-up'
  | 'move-down'
  | 'move-to-top'
  | 'move-to-bottom'

interface WidgetLayoutContextType {
  config: WidgetConfig
  moveWidget: (widgetId: string, action: MoveAction) => void
  moveWidgetToPosition: (widgetId: string, targetCol: number, targetRow: number) => void
  removeWidget: (widgetId: string) => void
  addWidget: (type: string, displayName: string, col: number, row: number) => void
  resetConfig: () => void
}

const WidgetLayoutContext = createContext<WidgetLayoutContextType | null>(null)

const recalculateRelativePositions = (widgets: Widget[]): Widget[] => {
  const sortedWidgets = [...widgets].sort((a, b) => {
    if (a.position.col !== b.position.col) {
      return a.position.col - b.position.col
    }
    return a.position.row - b.position.row
  })

  return sortedWidgets.map((widget, index) => ({
    ...widget,
    position: {...widget.position, relative: index + 1},
  }))
}

const normalizeRowNumbers = (widgets: Widget[], col: number): Widget[] => {
  const colWidgets = widgets.filter(w => w.position.col === col)
  const sortedColWidgets = [...colWidgets].sort((a, b) => a.position.row - b.position.row)

  const rowMapping = new Map<string, number>()
  sortedColWidgets.forEach((w, idx) => {
    rowMapping.set(w.id, idx + 1)
  })

  return widgets.map(w => {
    if (w.position.col === col) {
      return {...w, position: {...w.position, row: rowMapping.get(w.id)!}}
    }
    return w
  })
}

const moveWidgetLeft = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget || widget.position.col === LEFT_COLUMN) return widgets

  const col1Widgets = widgets.filter(w => w.position.col === LEFT_COLUMN)
  const maxRow = col1Widgets.length > 0 ? Math.max(...col1Widgets.map(w => w.position.row)) : 0

  return widgets.map(w =>
    w.id === widgetId ? {...w, position: {...w.position, col: LEFT_COLUMN, row: maxRow + 1}} : w,
  )
}

const moveWidgetRight = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget || widget.position.col === RIGHT_COLUMN) return widgets

  const col2Widgets = widgets.filter(w => w.position.col === RIGHT_COLUMN)
  const maxRow = col2Widgets.length > 0 ? Math.max(...col2Widgets.map(w => w.position.row)) : 0

  return widgets.map(w =>
    w.id === widgetId ? {...w, position: {...w.position, col: RIGHT_COLUMN, row: maxRow + 1}} : w,
  )
}

const moveWidgetLeftTop = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget || widget.position.col === LEFT_COLUMN) return widgets

  return widgets.map(w => {
    if (w.id === widgetId) {
      return {...w, position: {...w.position, col: LEFT_COLUMN, row: 1}}
    }
    if (w.position.col === LEFT_COLUMN) {
      return {...w, position: {...w.position, row: w.position.row + 1}}
    }
    return w
  })
}

const moveWidgetRightTop = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget || widget.position.col === RIGHT_COLUMN) return widgets

  return widgets.map(w => {
    if (w.id === widgetId) {
      return {...w, position: {...w.position, col: RIGHT_COLUMN, row: 1}}
    }
    if (w.position.col === RIGHT_COLUMN) {
      return {...w, position: {...w.position, row: w.position.row + 1}}
    }
    return w
  })
}

const moveWidgetUp = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget) return widgets

  const colWidgets = widgets.filter(w => w.position.col === widget.position.col)
  const sortedColWidgets = [...colWidgets].sort((a, b) => a.position.row - b.position.row)
  const currentIndex = sortedColWidgets.findIndex(w => w.id === widgetId)

  if (currentIndex <= 0) return widgets

  const targetWidget = sortedColWidgets[currentIndex - 1]

  return widgets.map(w => {
    if (w.id === widgetId) {
      return {...w, position: {...w.position, row: targetWidget.position.row}}
    }
    if (w.id === targetWidget.id) {
      return {...w, position: {...w.position, row: widget.position.row}}
    }
    return w
  })
}

const moveWidgetDown = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget) return widgets

  const colWidgets = widgets.filter(w => w.position.col === widget.position.col)
  const sortedColWidgets = [...colWidgets].sort((a, b) => a.position.row - b.position.row)
  const currentIndex = sortedColWidgets.findIndex(w => w.id === widgetId)

  if (currentIndex === -1 || currentIndex >= sortedColWidgets.length - 1) return widgets

  const targetWidget = sortedColWidgets[currentIndex + 1]

  return widgets.map(w => {
    if (w.id === widgetId) {
      return {...w, position: {...w.position, row: targetWidget.position.row}}
    }
    if (w.id === targetWidget.id) {
      return {...w, position: {...w.position, row: widget.position.row}}
    }
    return w
  })
}

const moveWidgetToTop = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget) return widgets

  const colWidgets = widgets.filter(w => w.position.col === widget.position.col)
  const sortedColWidgets = [...colWidgets].sort((a, b) => a.position.row - b.position.row)
  const currentIndex = sortedColWidgets.findIndex(w => w.id === widgetId)

  if (currentIndex <= 0) return widgets

  return widgets.map(w => {
    if (w.id === widgetId) {
      return {...w, position: {...w.position, row: 1}}
    }
    if (w.position.col === widget.position.col && w.id !== widgetId) {
      const widgetIndex = sortedColWidgets.findIndex(sw => sw.id === w.id)
      if (widgetIndex < currentIndex) {
        return {...w, position: {...w.position, row: w.position.row + 1}}
      }
    }
    return w
  })
}

const moveWidgetToBottom = (widgets: Widget[], widgetId: string): Widget[] => {
  const widget = widgets.find(w => w.id === widgetId)
  if (!widget) return widgets

  const colWidgets = widgets.filter(w => w.position.col === widget.position.col)
  const sortedColWidgets = [...colWidgets].sort((a, b) => a.position.row - b.position.row)
  const currentIndex = sortedColWidgets.findIndex(w => w.id === widgetId)

  if (currentIndex === -1 || currentIndex >= sortedColWidgets.length - 1) return widgets

  const maxRow = Math.max(...colWidgets.map(w => w.position.row))

  return widgets.map(w => {
    if (w.id === widgetId) {
      return {...w, position: {...w.position, row: maxRow}}
    }
    if (w.position.col === widget.position.col && w.id !== widgetId) {
      const widgetIndex = sortedColWidgets.findIndex(sw => sw.id === w.id)
      if (widgetIndex > currentIndex) {
        return {...w, position: {...w.position, row: w.position.row - 1}}
      }
    }
    return w
  })
}

export const WidgetLayoutProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const [config, setConfig] = useState<WidgetConfig>(DEFAULT_WIDGET_CONFIG)
  const {markDirty} = useWidgetDashboardEdit()

  const moveWidget = useCallback(
    (widgetId: string, action: MoveAction) => {
      setConfig(prevConfig => {
        let updatedWidgets = [...prevConfig.widgets]

        switch (action) {
          case 'move-left':
            updatedWidgets = moveWidgetLeft(updatedWidgets, widgetId)
            break
          case 'move-right':
            updatedWidgets = moveWidgetRight(updatedWidgets, widgetId)
            break
          case 'move-left-top':
            updatedWidgets = moveWidgetLeftTop(updatedWidgets, widgetId)
            break
          case 'move-right-top':
            updatedWidgets = moveWidgetRightTop(updatedWidgets, widgetId)
            break
          case 'move-up':
            updatedWidgets = moveWidgetUp(updatedWidgets, widgetId)
            break
          case 'move-down':
            updatedWidgets = moveWidgetDown(updatedWidgets, widgetId)
            break
          case 'move-to-top':
            updatedWidgets = moveWidgetToTop(updatedWidgets, widgetId)
            break
          case 'move-to-bottom':
            updatedWidgets = moveWidgetToBottom(updatedWidgets, widgetId)
            break
        }

        updatedWidgets = normalizeRowNumbers(updatedWidgets, LEFT_COLUMN)
        updatedWidgets = normalizeRowNumbers(updatedWidgets, RIGHT_COLUMN)
        updatedWidgets = recalculateRelativePositions(updatedWidgets)

        return {...prevConfig, widgets: updatedWidgets}
      })
      markDirty()
    },
    [markDirty],
  )

  const moveWidgetToPosition = useCallback(
    (widgetId: string, targetCol: number, targetRow: number) => {
      setConfig(prevConfig => {
        const widget = prevConfig.widgets.find(w => w.id === widgetId)
        if (!widget) return prevConfig

        const updatedWidgets = prevConfig.widgets.map(w => {
          if (w.id === widgetId) {
            return {...w, position: {...w.position, col: targetCol, row: targetRow}}
          }
          if (w.position.col === targetCol && w.position.row >= targetRow && w.id !== widgetId) {
            return {...w, position: {...w.position, row: w.position.row + 1}}
          }
          return w
        })

        const normalizedWidgets = normalizeRowNumbers(
          normalizeRowNumbers(updatedWidgets, LEFT_COLUMN),
          RIGHT_COLUMN,
        )
        const finalWidgets = recalculateRelativePositions(normalizedWidgets)
        return {...prevConfig, widgets: finalWidgets}
      })
      markDirty()
    },
    [markDirty],
  )

  const removeWidget = useCallback(
    (widgetId: string) => {
      setConfig(prevConfig => {
        const updatedWidgets = prevConfig.widgets.filter(w => w.id !== widgetId)
        const normalizedWidgets = normalizeRowNumbers(
          normalizeRowNumbers(updatedWidgets, LEFT_COLUMN),
          RIGHT_COLUMN,
        )
        const finalWidgets = recalculateRelativePositions(normalizedWidgets)
        return {...prevConfig, widgets: finalWidgets}
      })
      markDirty()
    },
    [markDirty],
  )

  const addWidget = useCallback(
    (type: string, displayName: string, col: number, row: number) => {
      setConfig(prevConfig => {
        const newWidget: Widget = {
          id: `${type}-widget-${crypto.randomUUID()}`,
          type,
          position: {col, row, relative: 0},
          title: displayName,
        }

        const updatedWidgets = prevConfig.widgets.map(w => {
          if (w.position.col === col && w.position.row >= row) {
            return {...w, position: {...w.position, row: w.position.row + 1}}
          }
          return w
        })

        const allWidgets = [...updatedWidgets, newWidget]
        const normalizedWidgets = normalizeRowNumbers(
          normalizeRowNumbers(allWidgets, LEFT_COLUMN),
          RIGHT_COLUMN,
        )
        const finalWidgets = recalculateRelativePositions(normalizedWidgets)

        return {...prevConfig, widgets: finalWidgets}
      })
      markDirty()
    },
    [markDirty],
  )

  const resetConfig = useCallback(() => {
    setConfig(DEFAULT_WIDGET_CONFIG)
  }, [])

  const value = {
    config,
    moveWidget,
    moveWidgetToPosition,
    removeWidget,
    addWidget,
    resetConfig,
  }

  return <WidgetLayoutContext.Provider value={value}>{children}</WidgetLayoutContext.Provider>
}

export function useWidgetLayout() {
  const context = useContext(WidgetLayoutContext)
  if (!context) {
    throw new Error('useWidgetLayout must be used within WidgetLayoutProvider')
  }
  return context
}
