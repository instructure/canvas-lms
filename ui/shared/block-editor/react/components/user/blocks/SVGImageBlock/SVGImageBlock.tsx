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

const DEFAULT_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="50" height="16" viewBox="0 0 50 16">
<text x="0" y="16" font-size="16">SVG</text>
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
