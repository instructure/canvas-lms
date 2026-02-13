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

import React, {useEffect} from 'react'
import {DragDropConnectorProps} from '../grid/DragDropWrapper'
import {View, ViewProps} from '@instructure/ui-view'

export type ColHeaderProps = {
  children?: React.ReactNode
  isSticky?: boolean
  isStacked?: boolean
  'data-cell-id'?: string
  'data-testid'?: string
} & Partial<DragDropConnectorProps> &
  ViewProps

export const ColHeader = ({
  children,
  isSticky,
  connectDragSource,
  connectDragPreview,
  connectDropTarget,
  isDragging,
  isStacked,
  'data-cell-id': dataCellId,
  ...viewProps
}: ColHeaderProps) => {
  // Filter out drag-drop specific props that shouldn't be passed to DOM
  const {onMove, onDragEnd, itemId, index, type, component, ...cleanViewProps} = viewProps as any

  // Use an empty image as the drag preview to prevent the browser from
  // screenshotting the table structure when dragging a <th> child
  useEffect(() => {
    if (connectDragPreview) {
      const emptyImage = new Image()
      emptyImage.src = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
      connectDragPreview(emptyImage, {captureDraggingState: true})
    }
  }, [connectDragPreview])

  const headerContent = (
    <div
      style={{
        opacity: isDragging ? 0.5 : 1,
        cursor: isDragging !== undefined ? 'grab' : 'default',
        transition: 'opacity 0.15s ease-in-out',
        width: cleanViewProps.width,
      }}
      data-testid="col-header-content"
    >
      {children}
    </div>
  )

  return (
    <View
      data-cell-id={dataCellId}
      as={isStacked ? 'div' : 'th'}
      scope="col"
      focusPosition="inset"
      elementRef={ref => {
        if (connectDropTarget && ref instanceof HTMLElement) {
          connectDropTarget(ref as any)
        }
      }}
      position={isSticky ? 'sticky' : 'static'}
      insetInlineStart={isSticky ? '0' : undefined}
      background={!cleanViewProps.background ? 'primary' : cleanViewProps.background}
      cursor={isDragging !== undefined ? 'grab' : 'default'}
      stacking="above"
      {...cleanViewProps}
    >
      {connectDragSource ? connectDragSource(headerContent) : headerContent}
    </View>
  )
}
