/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useRef, useEffect} from 'react'
import {buildSvg} from './svg'
import {PREVIEW_WIDTH, PREVIEW_HEIGHT} from './constants'

/**
 * Remove the node contents and append the svg element.
 */
function replaceSvg(svg, node) {
  if (!node) return
  while (node.firstChild) {
    node.removeChild(node.lastChild)
  }
  node.appendChild(svg)
}

const ImageCropperPreview = ({shape}) => {
  const wrapper = useRef(null)
  useEffect(() => {
    const svg = buildSvg(shape)
    replaceSvg(svg, wrapper.current)
  }, [shape])

  return (
    <div
      style={{
        position: 'relative',
        width: `${PREVIEW_WIDTH}px`,
        height: `${PREVIEW_HEIGHT}px`,
        top: 0,
        left: 0,
        overflow: 'hidden'
      }}
    >
      <img
        src="#"
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          height: '100%',
          width: '100%',
          objectFit: 'contain',
          textAlign: 'center',
          cursor: 'move'
        }}
      />
      <div
        id="cropShapeContainer"
        style={{
          position: 'absolute',
          top: 0,
          left: 0
        }}
        ref={wrapper}
      />
    </div>
  )
}

export default ImageCropperPreview
