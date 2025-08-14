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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import type {Widget, WidgetConfig} from '../types'
import {getWidget} from './WidgetRegistry'

const I18n = createI18nScope('widget_dashboard')

interface WidgetGridProps {
  config: WidgetConfig
}

const WidgetGrid: React.FC<WidgetGridProps> = ({config}) => {
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

  const calculateGridColumn = (widget: Widget) => {
    const startCol = widget.position.col
    const endCol = startCol + widget.size.width - 1
    return `${startCol} / ${endCol + 1}`
  }

  const calculateGridRow = (widget: Widget) => {
    const startRow = widget.position.row
    const endRow = startRow + widget.size.height - 1
    return `${startRow} / ${endRow + 1}`
  }

  const maxRows =
    config.widgets.length > 0
      ? Math.max(...config.widgets.map(widget => widget.position.row + widget.size.height - 1))
      : 1

  const renderWidgetInView = (widget: Widget) => (
    <div
      key={widget.id}
      data-testid={`widget-container-${widget.id}`}
      style={{
        gridColumn: calculateGridColumn(widget),
        gridRow: calculateGridRow(widget),
      }}
    >
      <View height="100%" style={{overflow: 'hidden'}}>
        {renderWidget(widget)}
      </View>
    </div>
  )

  return (
    <div
      data-testid="widget-grid"
      style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${config.columns}, 1fr)`,
        gridTemplateRows: `repeat(${maxRows}, 20rem)`,
        gap: '1rem',
        width: '100%',
        overflow: 'visible',
      }}
    >
      {config.widgets.map(widget => renderWidgetInView(widget))}
    </div>
  )
}

export default WidgetGrid
