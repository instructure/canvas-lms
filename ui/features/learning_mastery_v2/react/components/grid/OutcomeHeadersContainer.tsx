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

import React, {useEffect, useRef} from 'react'
import {DropTarget, DropTargetMonitor} from 'react-dnd'

interface Props {
  children: (connectDropTarget: (el: HTMLElement) => void) => React.ReactNode
  onDragLeave?: () => void
  connectDropTarget?: any
  isOver?: boolean
  canDrop?: boolean
}

const Component: React.FC<Props> = ({
  children,
  onDragLeave,
  connectDropTarget,
  isOver,
  canDrop,
}) => {
  const prevIsOverRef = useRef<boolean>() // To prevent initial call (isOver is false initially)

  useEffect(() => {
    if (prevIsOverRef.current === true && isOver === false && canDrop) {
      onDragLeave?.()
    }
    prevIsOverRef.current = isOver
  }, [isOver, canDrop, onDragLeave])

  return <>{children(connectDropTarget)}</>
}

export const OutcomeHeadersContainer = DropTarget(
  'outcome-header',
  {},
  (connect, monitor: DropTargetMonitor) => ({
    connectDropTarget: connect.dropTarget(),
    isOver: monitor.isOver({shallow: false}),
    canDrop: monitor.canDrop(),
  }),
)(Component) as React.ComponentType<Omit<Props, 'connectDropTarget' | 'isOver' | 'canDrop'>>
