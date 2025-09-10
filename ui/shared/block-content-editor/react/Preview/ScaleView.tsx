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

import {View} from '@instructure/ui-view'
import {PropsWithChildren, useRef, useLayoutEffect} from 'react'

export const ScaleView = (
  props: PropsWithChildren<{
    containerWidth: number
    contentWidth: number
  }>,
) => {
  const containerRef = useRef<HTMLDivElement>(null)
  const innerRef = useRef<HTMLDivElement>(null)

  useLayoutEffect(() => {
    const updateScale = () => {
      if (containerRef.current && innerRef.current) {
        const containerWidth = containerRef.current.offsetWidth
        const fixedContentWidth = props.contentWidth

        const calculatedScale = Math.min(containerWidth / fixedContentWidth, 1)

        innerRef.current.style.width = `${fixedContentWidth}px`
        innerRef.current.style.transform = `scale(${calculatedScale})`

        const contentHeight = innerRef.current.scrollHeight
        const scaledHeight = contentHeight * calculatedScale
        containerRef.current.style.height = `${scaledHeight}px`
      }
    }

    updateScale()

    const resizeObserver = new ResizeObserver(updateScale)
    if (containerRef.current) {
      resizeObserver.observe(containerRef.current)
    }
    const contentResizeObserver = new ResizeObserver(updateScale)
    if (innerRef.current) {
      contentResizeObserver.observe(innerRef.current)
    }

    return () => {
      resizeObserver.disconnect()
      contentResizeObserver.disconnect()
    }
  }, [props.contentWidth])

  return (
    <View
      width={props.containerWidth}
      borderWidth="small"
      borderRadius="medium"
      overflowX="hidden"
      overflowY="hidden"
    >
      <div
        ref={containerRef}
        style={{
          position: 'relative',
        }}
      >
        <div
          ref={innerRef}
          style={{
            position: 'absolute',
            transformOrigin: 'top left',
          }}
        >
          {props.children}
        </div>
      </div>
    </View>
  )
}
