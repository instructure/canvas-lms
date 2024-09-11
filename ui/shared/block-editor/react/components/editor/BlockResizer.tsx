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
import {getAspectRatio} from '../../utils/size'
import Moveable, {type OnResize} from 'react-moveable'

type Sz = {
  width: number
  height: number
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
  const [currSz, setCurrSz] = useState<Sz>(() => {
    const {width, height} = node.data.props
    if (width) {
      return {width, height}
    } else if (node.dom) {
      const rect = node.dom.getBoundingClientRect()
      return {width: rect.width, height: rect.height}
    } else {
      return {width: 0, height: 0}
    }
  })

  const isDragging = useRef(false)

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
      }
      if (newWidth > 0 && newHeight > 0) {
        newWidth = Math.max(newWidth, 24)
        newHeight = Math.max(newHeight, 24)
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
        setProp((props: any) => {
          props.width = newWidth
          props.height = newHeight
        })
      }
    },
    [currSz.height, currSz.width, maintainAspectRatio, node.dom, setProp]
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
      'width' in node.data.props &&
      (node.data.props.width !== currSz.width || node.data.props.height !== currSz.height)
    ) {
      setCurrSz({
        width: node.data.props.width,
        height: node.data.props.height,
      })
    }
  }, [currSz.height, currSz.width, node.data.props.height, node.data.props.width, node.data.props])

  const handleResizeStart = useCallback(() => {
    isDragging.current = true
    const myToolbar = mountPoint.querySelector('.block-editor-editor .block-toolbar') as HTMLElement
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
    setProp((props: any) => {
      props.width = currSz.width
      props.height = currSz.height
    })
    const myToolbar = mountPoint.querySelector('.block-editor-editor .block-toolbar') as HTMLElement
    if (myToolbar) {
      myToolbar.style.visibility = 'visible'
    }
  }, [currSz.height, currSz.width, mountPoint, setProp])

  return (
    <Moveable
      className="block-resizer"
      target={node.dom}
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
