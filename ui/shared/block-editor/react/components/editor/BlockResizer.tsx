/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {useNode, type Node} from '@craftjs/core'
import {getToolbarPos as getToolbarPosUtil} from '../../utils/renderNodeHelpers'
import {getAspectRatio} from '../../utils/size'

const offset = 5

type Rect = {
  top: number
  left: number
  width: number
  height: number
}

export const getNewSz = (
  corner: string,
  currRect: Rect,
  dragStart: {x: number; y: number},
  event: DragEvent
) => {
  let width = 0
  switch (corner) {
    case 'nw':
    case 'sw':
      width = currRect.width - (event.clientX - dragStart.x)
      break
    case 'ne':
    case 'se':
      width = currRect.width + (event.clientX - dragStart.x)
      break
  }
  let height = 0
  switch (corner) {
    case 'nw':
    case 'ne':
      height = currRect.height - (event.clientY - dragStart.y)
      break
    case 'sw':
    case 'se':
      height = currRect.height + (event.clientY - dragStart.y)
      break
  }
  return {width, height}
}

type BlockResizeProps = {
  mountPoint: HTMLElement
}

const BlockResizer = ({mountPoint}: BlockResizeProps) => {
  const {
    actions: {setProp},
    node,
    maintainAspectRatio,
  } = useNode((n: Node) => {
    return {
      maintainAspectRatio: !!node?.data?.props?.maintainAspectRatio,
      node: n,
    }
  })
  const [nwRef, setnwRef] = useState<HTMLDivElement | null>(null)
  const [neRef, setneRef] = useState<HTMLDivElement | null>(null)
  const [seRef, setseRef] = useState<HTMLDivElement | null>(null)
  const [swRef, setswRef] = useState<HTMLDivElement | null>(null)
  const [currRect, setCurrRect] = useState<Rect>({left: 0, top: 0, width: 0, height: 0})

  const dragHandleStart = useRef({x: 0, y: 0})
  const isDragging = useRef(false)

  const getToolbarPos = useCallback(() => {
    return getToolbarPosUtil(node.dom as HTMLElement, mountPoint, null, false)
  }, [mountPoint, node.dom])

  const handleResizeKeys = useCallback(
    event => {
      if (!node.dom) return
      if (!event.altKey) return
      let dir = 1
      const resizeKeys = ['ArrowRight', 'ArrowLeft', 'ArrowUp', 'ArrowDown']
      if (resizeKeys.includes(event.key)) {
        event.preventDefault()
        dir = window.getComputedStyle(node.dom).direction === 'ltr' ? 1 : -1
      }
      const step = event.shiftKey ? 10 : 1

      let newWidth = currRect.width
      let newHeight = currRect.height
      switch (event.key) {
        case 'ArrowRight':
          newWidth += step * dir
          break
        case 'ArrowLeft':
          newWidth -= step * dir
          break
        case 'ArrowUp':
          newHeight -= step
          break
        case 'ArrowDown':
          newHeight += step
          break
      }
      if (newWidth > 0 && newHeight > 0) {
        newWidth = Math.max(newWidth, 24)
        newHeight = Math.max(newHeight, 24)
        if (maintainAspectRatio) {
          const aspectRatio = getAspectRatio(currRect.width, currRect.height)
          if (newHeight !== currRect.height) {
            newWidth = newHeight * aspectRatio
          } else {
            newHeight = newWidth / aspectRatio
          }
        }
        const myblock = node.dom as HTMLElement
        myblock.style.width = `${newWidth}px`
        myblock.style.height = `${newHeight}px`
        const {top, left} = getToolbarPos()
        setCurrRect({left, top, width: newWidth, height: newHeight})
        setProp((props: any) => {
          props.width = newWidth
          props.height = newHeight
        })
      }
    },
    [currRect.height, currRect.width, getToolbarPos, maintainAspectRatio, node.dom, setProp]
  )

  useEffect(() => {
    document.addEventListener('keydown', handleResizeKeys)
    return () => {
      document.removeEventListener('keydown', handleResizeKeys)
    }
  }, [handleResizeKeys])

  useEffect(() => {
    if (node.dom && (currRect.width === 0 || currRect.height === 0)) {
      const {top, left} = getToolbarPosUtil(node.dom as HTMLElement, mountPoint, null, false)
      const {width, height} = (node.dom as HTMLElement).getBoundingClientRect()
      setCurrRect({left, top, width, height})
    }
  }, [currRect.height, currRect.width, mountPoint, node.dom])

  useEffect(() => {
    if (
      !isDragging.current &&
      'width' in node.data.props &&
      (node.data.props.width !== currRect.width || node.data.props.height !== currRect.height)
    ) {
      // assume height is there too then
      const {top, left} = getToolbarPosUtil(node.dom as HTMLElement, mountPoint, null, false)
      setCurrRect({
        left,
        top,
        width: node.data.props.width,
        height: node.data.props.height,
      })
    }
  }, [
    currRect.height,
    currRect.left,
    currRect.top,
    currRect.width,
    mountPoint,
    node.data.props,
    node.dom,
  ])

  const handleDrag = useCallback(
    (event: DragEvent) => {
      const myblock = node.dom as HTMLElement
      const corner = (event.currentTarget as HTMLElement).dataset.corner
      if (!corner) return
      let {width, height} = getNewSz(corner, currRect, dragHandleStart.current, event)

      if (width > 0 && height > 0) {
        width = Math.max(width, 24)
        height = Math.max(height, 24)
        if (maintainAspectRatio) {
          const aspectRatio = getAspectRatio(currRect.width, currRect.height)
          if (aspectRatio > 1) {
            width = height * aspectRatio
          } else {
            height = width / aspectRatio
          }
        }
        myblock.style.width = `${width}px`
        myblock.style.height = `${height}px`
        const {top, left} = getToolbarPos()
        setCurrRect({left, top, width, height})
      }
    },
    [currRect, getToolbarPos, maintainAspectRatio, node.dom]
  )

  const handleDragEnd = useCallback(
    (event: Event) => {
      event.currentTarget?.removeEventListener('drag', handleDrag)
      event.currentTarget?.removeEventListener('dragend', handleDragEnd)

      const {width, height} = (node.dom as HTMLElement).getBoundingClientRect()
      const {top, left} = getToolbarPos()
      setProp((props: any) => {
        props.width = width
        props.height = height
      })
      setCurrRect({left, top, width, height})
      isDragging.current = false
      const myToolbar = document.querySelector('.block-editor-editor .block-toolbar') as HTMLElement
      if (myToolbar) {
        myToolbar.style.visibility = 'initial'
      }
    },
    [getToolbarPos, handleDrag, node.dom, setProp]
  )

  const handleDragStart = useCallback(
    (event: DragEvent) => {
      event.stopPropagation()
      if (!event.dataTransfer) return
      // @ts-expect-error
      event.dataTransfer.mozShowFailAnimation = false // see https://github.com/whatwg/html/issues/10039
      event.dataTransfer.setDragImage(event.target as HTMLElement, 0, 0)
      const target = event.currentTarget as HTMLElement

      dragHandleStart.current = {x: event.clientX, y: event.clientY}
      target.addEventListener('drag', handleDrag)
      target.addEventListener('dragend', handleDragEnd)
      isDragging.current = true

      const myToolbar = document.querySelector('.block-editor-editor .block-toolbar') as HTMLElement
      if (myToolbar) {
        myToolbar.style.visibility = 'hidden'
      }
    },
    [handleDrag, handleDragEnd]
  )

  useEffect(() => {
    if (nwRef && neRef && seRef && swRef) {
      nwRef.addEventListener('dragstart', handleDragStart)
      neRef.addEventListener('dragstart', handleDragStart)
      seRef.addEventListener('dragstart', handleDragStart)
      swRef.addEventListener('dragstart', handleDragStart)
    }
    return () => {
      nwRef?.removeEventListener('dragstart', handleDragStart)
      neRef?.removeEventListener('dragstart', handleDragStart)
      seRef?.removeEventListener('dragstart', handleDragStart)
      swRef?.removeEventListener('dragstart', handleDragStart)
    }
  }, [handleDragEnd, handleDragStart, neRef, nwRef, seRef, swRef])

  return (
    <>
      <div
        ref={el => setnwRef(el)}
        data-corner="nw"
        className="block-resizer nw"
        draggable="true"
        style={{left: `${currRect.left - offset}px`, top: `${currRect.top - offset}px`}}
      />
      <div
        ref={el => setneRef(el)}
        data-corner="ne"
        className="block-resizer ne"
        draggable="true"
        style={{
          left: `${currRect.left + currRect.width - offset}px`,
          top: `${currRect.top - offset}px`,
        }}
      />
      <div
        ref={el => setseRef(el)}
        data-corner="se"
        className="block-resizer se"
        draggable="true"
        style={{
          left: `${currRect.left + currRect.width - offset}px`,
          top: `${currRect.top + currRect.height - offset}px`,
        }}
      />
      <div
        ref={el => setswRef(el)}
        data-corner="sw"
        className="block-resizer sw"
        draggable="true"
        style={{
          left: `${currRect.left - offset}px`,
          top: `${currRect.top + currRect.height - offset}px`,
        }}
      />
    </>
  )
}

export {BlockResizer}
