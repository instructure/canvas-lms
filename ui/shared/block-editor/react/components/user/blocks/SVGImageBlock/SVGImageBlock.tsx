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

import React from 'react'
import {useNode} from '@craftjs/core'

const CIRCLE = '<svg><circle cx="250" cy="250" r="250" /></svg>'

type SVGImageBlockProps = {
  src: string
  color?: string
  width?: number
  height?: number
}

const SVGImageBlock = ({src = CIRCLE, color = 'inherit', width, height}: SVGImageBlockProps) => {
  const {
    connectors: {connect, drag},
  } = useNode()

  return (
    <div
      style={{color, width: width || 'auto', height: height || 'auto'}}
      ref={ref => ref && connect(drag(ref))}
      dangerouslySetInnerHTML={{__html: src}}
    />
  )
}

SVGImageBlock.craft = {
  displayName: 'SVG Image',
  defaultProps: {
    src: CIRCLE,
  },
}

export {SVGImageBlock}
