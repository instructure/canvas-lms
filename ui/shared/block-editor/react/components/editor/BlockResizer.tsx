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
import Moveable, {type OnResize} from 'react-moveable'
import {getAspectRatio, percentSize} from '../../utils'
import {type ResizableProps, type SizeVariant, type Sz} from './types'
import {px} from '@instructure/ui-utils'

type BlockResizeProps = {
  mountPoint: HTMLElement
  sizeVariant: SizeVariant
}

const BlockResizer = ({mountPoint, sizeVariant}: BlockResizeProps) => {
  const {
    actions: {setProp},
    maintainAspectRatio,
    node,
    nodeProps,
  } = useNode((n: Node) => {
    return {
      maintainAspectRatio: !!n.data.props.maintainAspectRatio,
      node: n,
      nodeProps: n.data.props as ResizableProps,
    }
  })
  const [currSz, setCurrSz] = useState<Sz>({width: 0, height: 0})
  const isDragging = useRef(false)

  useEffect(() => {
    if (node.dom) {
      const rect = node.dom.getBoundingClientRect()
      setCurrSz({width: rect.width, height: rect.height})
    }
  }, [node.dom])

  const setNewSize = useCallback(
    (newWidth: number, newHeight: number) => {
      if (maintainAspectRatio) {
        const aspectRatio = getAspectRatio(currSz.width, currSz.height)
        if (newHeight !== currSz.height) {
          newWidth = newHeight * aspectRatio
        } else {
          newHeight = newWidth / aspectRatio
        }
      }

      const myblock = node.dom as HTMLElement
      myblock.style.width = `${newWidth}px`
      myblock.style.height = `${newHeight}px`

      setCurrSz({width: newWidth, height: newHeight})

      let propWidth = newWidth,
        propHeight = newHeight
      if (sizeVariant === 'percent') {
        const parent = node.dom?.offsetParent
        if (parent) {
          // assume all 4 sides have the same padding
          const padding = px(window.getComputedStyle(parent).getPropertyValue('padding'))
          propWidth = percentSize(parent.clientWidth - padding, newWidth)
        }
      }
      setProp((props: any) => {
        props.width = propWidth
        props.height = propHeight
      })
    },
    [currSz.height, currSz.width, maintainAspectRatio, node.dom, setProp, sizeVariant],
  )

  const handleResizeKeys = useCallback(
    (event: KeyboardEvent) => {
      if (!node.dom) return
      if (!event.altKey) return

      let dir = 1
      const resizeKeys = ['ArrowRight', 'ArrowLeft', 'ArrowUp', 'ArrowDown']
      if (resizeKeys.includes(event.key)) {
        event.preventDefault()
        dir = window.getComputedStyle(node.dom).direction === 'rtl' ? -1 : 1
      }
      const step = event.shiftKey ? 10 : 1
      let newWidth = currSz.width
      let newHeight = currSz.height
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
        default:
          return
      }
      if (newWidth > 0 && newHeight > 0) {
        newWidth = Math.max(newWidth, 24)
        newHeight = Math.max(newHeight, 19) // min height of textblock is 1.2rem or 19.2px
        setNewSize(newWidth, newHeight)
      }
    },
    [node.dom, currSz.width, currSz.height, setNewSize],
  )

  useEffect(() => {
    document.addEventListener('keydown', handleResizeKeys)
    return () => {
      document.removeEventListener('keydown', handleResizeKeys)
    }
  }, [handleResizeKeys])

  useEffect(() => {
    if (
      !isDragging.current &&
      Number.isFinite(nodeProps.width) &&
      Number.isFinite(nodeProps.height) &&
      (nodeProps.width !== currSz.width || nodeProps.height !== currSz.height)
    ) {
      setCurrSz({
        width: nodeProps.width as number,
        height: nodeProps.height as number,
      })
    }
  }, [currSz.height, currSz.width, nodeProps.height, nodeProps.width, nodeProps])

  const handleResizeStart = useCallback(() => {
    isDragging.current = true
    const myToolbar = mountPoint.querySelector('.block-toolbar') as HTMLElement
    if (myToolbar) {
      myToolbar.style.visibility = 'hidden'
    }
  }, [mountPoint])

  const handleResize = useCallback(({target, width, height, delta}: OnResize) => {
    delta[0] && (target!.style.width = `${width}px`)
    delta[1] && (target!.style.height = `${height}px`)
    setCurrSz({width, height})
  }, [])

  const handleResizeEnd = useCallback(() => {
    isDragging.current = false
    setNewSize(currSz.width, currSz.height)
    const myToolbar = mountPoint.querySelector('.block-toolbar') as HTMLElement
    if (myToolbar) {
      myToolbar.style.visibility = 'visible'
    }
  }, [currSz.height, currSz.width, mountPoint, setNewSize])

  return (
    <Moveable
      className="block-resizer"
      target={node.dom}
      renderDirections={['nw', 'ne', 'sw', 'se']}
      resizable={true}
      throttleSize={1}
      keepRatio={maintainAspectRatio}
      useResizeObserver={true}
      onResizeStart={handleResizeStart}
      onResize={handleResize}
      onResizeEnd={handleResizeEnd}
    />
  )
}

export {BlockResizer}
