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
import type {ConnectDragSource, ConnectDropTarget} from 'react-dnd'
import {ColumnHeader, ColumnHeaderProps} from './ColumnHeader'

export interface DraggableColumnHeaderProps extends ColumnHeaderProps {
  connectDragSource?: ConnectDragSource
  connectDropTarget?: ConnectDropTarget
  isDragging?: boolean
}

export const DraggableColumnHeader: React.FC<DraggableColumnHeaderProps> = ({
  title,
  optionsMenuTriggerLabel,
  optionsMenuItems,
  connectDragSource,
  connectDropTarget,
  isDragging,
}) => {
  const headerStyle = useMemo(
    () => ({
      opacity: isDragging ? 0.5 : 1,
      cursor: 'grab',
      transition: 'opacity 0.15s ease-in-out',
    }),
    [isDragging],
  )

  const headerContent = (
    <div style={headerStyle}>
      <ColumnHeader
        title={title}
        optionsMenuTriggerLabel={optionsMenuTriggerLabel}
        optionsMenuItems={optionsMenuItems}
      />
    </div>
  )

  return (
    <>
      {connectDragSource && connectDropTarget
        ? connectDragSource(connectDropTarget(headerContent))
        : headerContent}
    </>
  )
}
