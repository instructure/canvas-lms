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

import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import type {Widget, WidgetConfig} from '../types'
import {getWidget} from './WidgetRegistry'
import {useResponsiveContext} from '../hooks/useResponsiveContext'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('widget_dashboard')

const sortWidgetsForStacking = (widgets: Widget[]): Widget[] => {
  return [...widgets].sort((a, b) => {
    return a.position.relative - b.position.relative
  })
}

const widgetsAsColumns = (widgets: Widget[]): Widget[][] => {
  const inColumns = widgets.reduce(
    (acc, val) => {
      const column = val.position.col || 1
      acc[column - 1].push(val)
      return acc
    },
    [[] as Widget[], [] as Widget[]] as Widget[][],
  )

  inColumns.forEach((column, idx) => {
    inColumns[idx] = column.sort((a, b) => a.position.row - b.position.row)
  })

  return inColumns
}

interface WidgetGridProps {
  config: WidgetConfig
}

const WidgetGrid: React.FC<WidgetGridProps> = ({config}) => {
  const {matches} = useResponsiveContext()
  const sortedWidgets = useMemo(() => sortWidgetsForStacking(config.widgets), [config.widgets])
  const widgetsByColumn = useMemo(() => widgetsAsColumns(config.widgets), [config.widgets])

  const renderWidget = (widget: Widget) => {
    const widgetRenderer = getWidget(widget.type)

    if (!widgetRenderer) {
      return (
        <Text color="danger">{I18n.t('Unknown widget type: %{type}', {type: widget.type})}</Text>
      )
    }

    const WidgetComponent = widgetRenderer.component
    return <WidgetComponent widget={widget} />
  }

  const renderWidgetInView = (widget: Widget, key?: string) => (
    <Flex.Item key={key || widget.id} data-testid={`widget-container-${widget.id}`}>
      {renderWidget(widget)}
    </Flex.Item>
  )

  const renderDesktopGrid = () => (
    <Flex data-testid="widget-columns" direction="row" gap="x-small" alignItems="start">
      <Flex.Item shouldGrow shouldShrink width="66%">
        <Flex direction="column" gap="x-small" data-testid="widget-column-1" width="100%">
          {widgetsByColumn[0].map(widget => (
            <Flex.Item key={widget.id} data-testid={`widget-container-${widget.id}`}>
              {renderWidget(widget)}
            </Flex.Item>
          ))}
        </Flex>
      </Flex.Item>
      <Flex.Item shouldGrow shouldShrink width="33%">
        <Flex direction="column" gap="x-small" data-testid="widget-column-2" width="100%">
          {widgetsByColumn[1].map(widget => renderWidgetInView(widget))}
        </Flex>
      </Flex.Item>
    </Flex>
  )

  const renderTabletStack = () => (
    <Flex data-testid="widget-columns" width="100%">
      <Flex.Item
        data-testid="widget-column-tablet"
        overflowX="visible"
        overflowY="visible"
        width="100%"
      >
        {sortedWidgets.map(widget => renderWidgetInView(widget))}
      </Flex.Item>
    </Flex>
  )

  const renderMobileStack = renderTabletStack

  if (matches.includes('mobile')) {
    return renderMobileStack()
  } else if (matches.includes('tablet')) {
    return renderTabletStack()
  } else {
    return renderDesktopGrid()
  }
}

export default WidgetGrid
