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

import React, {useEffect, useState} from 'react'
import {useNode} from '@craftjs/core'
import {validateSVG} from '../../../../utils'
import {SVGImageToolbar} from './SVGImageToolbar'

const DEFAULT_SVG = `<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
<defs>
  <pattern id="striped-pattern" patternUnits="userSpaceOnUse" width="20" height="20" patternTransform="rotate(45)">
    <rect width="10" height="20" fill="#f5f5f5"></rect>
    <rect x="10" width="10" height="20" fill="#a5a5a5"></rect>
  </pattern>
</defs>
<rect width="100%" height="100%" fill="url(#striped-pattern)"></rect>
</svg>`

type SVGImageBlockProps = {
  src?: string
  color?: string
  width?: number
  height?: number
}

const SVGImageBlock = ({
  src = DEFAULT_SVG,
  color = 'inherit',
  width,
  height,
}: SVGImageBlockProps) => {
  const {
    connectors: {connect, drag},
  } = useNode()
  const [svg, setSvg] = useState<string>(validateSVG(src) ? src : DEFAULT_SVG)

  // TODO: can append the svg element from the document fragment to the div
  useEffect(() => {
    setSvg(validateSVG(src) ? src : DEFAULT_SVG)
  }, [src])

  return (
    <div
      className="svg-image-block"
      style={{color, width: width || 'auto', height: height || 'auto'}}
      ref={ref => ref && connect(drag(ref))}
      dangerouslySetInnerHTML={{__html: svg}}
    />
  )
}

SVGImageBlock.craft = {
  displayName: 'SVG Image',
  defaultProps: {
    src: DEFAULT_SVG,
  },
  related: {
    toolbar: SVGImageToolbar,
  },
}

export {SVGImageBlock, type SVGImageBlockProps}
