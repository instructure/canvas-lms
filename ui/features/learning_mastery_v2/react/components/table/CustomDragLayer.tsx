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

import React from 'react'
import DragLayer from 'react-dnd/lib/DragLayer'
import {DragLayerMonitor} from 'react-dnd'
import {View} from '@instructure/ui-view'
import {CELL_HEIGHT, COLUMN_WIDTH} from '@canvas/outcomes/react/utils/constants'

interface CustomDragLayerProps {
  renderItem?: (item: any) => React.ReactNode
}

interface CollectedProps {
  item: any
  itemType: string | symbol | null
  currentOffset: {x: number; y: number} | null
  isDragging: boolean
}

const getItemStyles = (currentOffset: {x: number; y: number} | null) => {
  if (!currentOffset) {
    return {
      display: 'none',
    }
  }

  const {x, y} = currentOffset
  const transform = `translate(${x}px, ${y}px)`

  return {
    transform,
    WebkitTransform: transform,
    width: COLUMN_WIDTH,
    height: CELL_HEIGHT,
  }
}

const CustomDragLayerComponent: React.FC<CustomDragLayerProps & CollectedProps> = ({
  renderItem,
  item,
  isDragging,
  currentOffset,
}) => {
  if (!isDragging) {
    return null
  }

  return (
    <div
      style={{
        position: 'fixed',
        pointerEvents: 'none',
        zIndex: 1000,
        left: 0,
        top: 0,
        width: '100%',
        height: '100%',
      }}
    >
      <div style={getItemStyles(currentOffset)}>
        <View
          as="div"
          padding="x-small"
          background="secondary"
          shadow="resting"
          style={{
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            height: '100%',
            display: 'flex',
            alignItems: 'center',
            boxSizing: 'border-box',
          }}
        >
          {renderItem && item ? renderItem(item) : item?.label || 'Dragging...'}
        </View>
      </div>
    </div>
  )
}

export const CustomDragLayer = DragLayer<CustomDragLayerProps, CollectedProps>(
  (monitor: DragLayerMonitor) => ({
    item: monitor.getItem(),
    itemType: monitor.getItemType(),
    currentOffset: monitor.getSourceClientOffset(),
    isDragging: monitor.isDragging(),
  }),
)(CustomDragLayerComponent)
