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

// A generic drag-and-drop wrapper component using react-dnd
// It can be used in other places as well in the future
import React from 'react'
import {
  DragSource,
  DropTarget,
  DragSourceMonitor,
  DropTargetMonitor,
  ConnectDragSource,
  ConnectDropTarget,
} from 'react-dnd'
import {flowRight as compose} from 'lodash'

interface DragItem {
  id: string | number
  index: number
  originalIndex: number
}

export interface DragDropConnectorProps {
  connectDragSource?: ConnectDragSource
  connectDropTarget?: ConnectDropTarget
  isDragging?: boolean
}

interface DragDropWrapperConfig {
  component: React.ComponentType<any>
  type: string
  itemId: string | number
  index: number
  onMove: (draggedId: string | number, hoverIndex: number) => void
  onDragEnd?: () => void
  [key: string]: any
}

type DragDropWrapperComponentProps = DragDropWrapperConfig & DragDropConnectorProps

const DragDropWrapperComponent: React.FC<DragDropWrapperComponentProps> = ({
  component: Component,
  ...props
}) => {
  return <Component {...props} />
}

const dragSource = {
  beginDrag(props: DragDropWrapperComponentProps): DragItem {
    return {
      id: props.itemId,
      index: props.index,
      originalIndex: props.index,
    }
  },
  endDrag(props: DragDropWrapperComponentProps, monitor: DragSourceMonitor) {
    const dragItem = monitor.getItem() as DragItem

    if (!monitor.didDrop()) {
      props.onMove(dragItem.id, dragItem.originalIndex)
    } else if (props.onDragEnd) {
      props.onDragEnd()
    }
  },
}

const dropTarget = {
  hover(props: DragDropWrapperComponentProps, monitor: DropTargetMonitor) {
    const dragItem = monitor.getItem() as DragItem
    if (dragItem.id !== props.itemId) {
      props.onMove(dragItem.id, props.index)
      dragItem.index = props.index
    }
  },
}

export default compose(
  DropTarget(
    (props: DragDropWrapperComponentProps) => props.type,
    dropTarget,
    connect => ({
      connectDropTarget: connect.dropTarget(),
    }),
  ),
  DragSource(
    (props: DragDropWrapperComponentProps) => props.type,
    dragSource,
    (connect, monitor) => ({
      connectDragSource: connect.dragSource(),
      isDragging: monitor.isDragging(),
    }),
  ),
)(DragDropWrapperComponent)
