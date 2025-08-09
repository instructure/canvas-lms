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
import {Grid} from '@instructure/ui-grid'
import type {Widget, WidgetConfig} from '../types'
import {WIDGET_TYPES} from '../constants'
import CourseWorkSummaryWidget from './widgets/CourseWorkSummaryWidget'

interface WidgetGridProps {
  config: WidgetConfig
}

const WidgetGrid: React.FC<WidgetGridProps> = ({config}) => {
  const renderWidget = (widget: Widget) => {
    switch (widget.type) {
      case WIDGET_TYPES.COURSE_WORK_SUMMARY:
        return <CourseWorkSummaryWidget />
      default:
        return null
    }
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

  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${config.columns}, 1fr)`,
        gap: '1rem',
        width: '100%',
      }}
      data-testid="widget-grid"
    >
      {config.widgets.map(widget => (
        <div
          key={widget.id}
          style={{
            gridColumn: calculateGridColumn(widget),
            gridRow: calculateGridRow(widget),
          }}
          data-testid={`widget-${widget.id}`}
        >
          {renderWidget(widget)}
        </div>
      ))}
    </div>
  )
}

export default WidgetGrid
