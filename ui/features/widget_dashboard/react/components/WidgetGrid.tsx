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
import {View} from '@instructure/ui-view'
import {Responsive} from '@instructure/ui-responsive'
import type {Widget, WidgetConfig} from '../types'
import {getWidget} from './WidgetRegistry'
import {ResponsiveProvider} from '../hooks/useResponsiveContext'

const I18n = createI18nScope('widget_dashboard')

const responsiveQuerySizes = ({
  mobile = false,
  tablet = false,
  desktop = false,
}: {mobile?: boolean; tablet?: boolean; desktop?: boolean} = {}) => {
  const querySizes: Record<string, {minWidth?: string; maxWidth?: string}> = {}
  if (mobile) {
    querySizes.mobile = {maxWidth: '639px'}
  }
  if (tablet) {
    querySizes.tablet = {minWidth: mobile ? '640px' : '0px', maxWidth: '1023px'}
  }
  if (desktop) {
    querySizes.desktop = {minWidth: tablet ? '1024px' : '640px'}
  }
  return querySizes
}

const sortWidgetsForStacking = (widgets: Widget[]): Widget[] => {
  return [...widgets].sort((a, b) => {
    return a.position.relative - b.position.relative
  })
}

const widgetsAsColumns = (widgets: Widget[]): Widget[][] => {
  const inColumns = widgets.reduce((acc, val) => {
    const column = val.position.col || 1
    acc[column - 1].push(val)
    return acc
  }, [[] as Widget[], [] as Widget[]] as Widget[][])

  inColumns.forEach((column, idx) => {
    inColumns[idx] = column.sort((a, b) => a.position.row = b.position.row)
  })

  return inColumns
}

interface WidgetGridProps {
  config: WidgetConfig
}

const WidgetGrid: React.FC<WidgetGridProps> = ({config}) => {
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
    <div
      key={key || widget.id}
      data-testid={`widget-container-${widget.id}`}
      style={{ marginBottom: '1rem' }}
    >
      <View height="100%" style={{overflow: 'hidden'}}>
        {renderWidget(widget)}
      </View>
    </div>
  )

  const renderDesktopGrid = () => (
    <div
      data-testid="widget-columns"
      style={{
        width: '100%',
        overflow: 'visible',
        display: 'flex'
      }}
    >
      <div
        data-testid="widget-column-1"
        style={{
          flexGrow: 2,
          marginRight: '1rem',
        }}
      >
        {widgetsByColumn[0].map(widget => (
          <div
            key={widget.id}
            data-testid={`widget-container-${widget.id}`}
            style={{
              marginBottom: '1rem'
            }}
          >
            <View height="100%" style={{overflow: 'hidden'}}>
              {renderWidget(widget)}
            </View>
          </div>
        ))}
      </div>
      <div
        data-testid="widget-column-1"
        style={{
          flexGrow: 1
        }}
      >
        {widgetsByColumn[1].map(widget => (renderWidgetInView(widget)))}
      </div>
    </div>
  )

  const renderTabletStack = () => (
    <div
      data-testid="widget-columns"
      style={{
        width: '100%',
        overflow: 'visible',
        display: 'flex'
      }}
    >
      <div data-testid="widget-column-tablet">
        {sortedWidgets.map((widget) => renderWidgetInView(widget))}
      </div>
    </div>
  )

  const renderMobileStack = renderTabletStack

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, tablet: true, desktop: true})}
      render={(_props, matches) => {
        const matchesArray = matches || ['desktop']

        let content
        if (matchesArray.includes('mobile')) {
          content = renderMobileStack()
        } else if (matchesArray.includes('tablet')) {
          content = renderTabletStack()
        } else {
          content = renderDesktopGrid()
        }

        return <ResponsiveProvider matches={matchesArray}>{content}</ResponsiveProvider>
      }}
    />
  )
}

export default WidgetGrid
