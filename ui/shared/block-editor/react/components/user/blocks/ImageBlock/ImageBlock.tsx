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

import {Img} from '@instructure/ui-img'

import {ImageBlockToolbar} from './ImageBlockToolbar'

export type ImageConstraint = 'cover' | 'contain'
export type ImageVariant = 'default' | 'hero'
export const HeroImageHeight = '184px'

type ImageBlockProps = {
  src?: string
  width?: number
  height?: number
  constraint?: ImageConstraint
}

const ImageBlock = ({src, width, height, constraint}: ImageBlockProps) => {
  const {
    connectors: {connect, drag},
  } = useNode()

  if (!src) {
    return (
      <div className="image-block__empty" ref={el => el && connect(drag(el as HTMLImageElement))} />
    )
  } else {
    return (
      <Img
        display="inline-block"
        elementRef={el => el && connect(drag(el as HTMLImageElement))}
        src={src || ImageBlock.craft.defaultProps.imageSrc}
        constrain={constraint || ImageBlock.craft.defaultProps.constraint}
        width={`${width}px`}
        height={`${height}px`}
      />
    )
  }
}

ImageBlock.craft = {
  displayName: 'Image',
  defaultProps: {
    imageSrc: '',
    variant: 'default' as ImageVariant,
    constraint: 'cover' as ImageConstraint,
  },
  related: {
    toolbar: ImageBlockToolbar,
  },
}

export {ImageBlock}
