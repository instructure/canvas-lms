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

import React, {useCallback} from 'react'
import {useEditor, useNode, type Node} from '@craftjs/core'

import {Img} from '@instructure/ui-img'

import {ImageBlockToolbar} from './ImageBlockToolbar'
import {useClassNames, getAspectRatio} from '../../../../utils'
import {
  EMPTY_IMAGE_WIDTH,
  EMPTY_IMAGE_HEIGHT,
  type ImageBlockProps,
  type ImageVariant,
  type ImageConstraint,
} from './types'
import {BlockResizer} from '../../../editor/BlockResizer'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor/image-block')

const ImageBlock = ({src, width, height, constraint, maintainAspectRatio}: ImageBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    actions: {setProp},
    connectors: {connect, drag},
    node,
  } = useNode((n: Node) => {
    return {
      node: n,
    }
  })
  const clazz = useClassNames(enabled, {empty: !src}, ['block', 'image-block'])
  const sty: any = {}
  if (width) {
    sty.width = `${width}px`
  }
  if (height) {
    sty.height = `${height}px`
  }

  const setAspectRatio = useCallback(
    (img: HTMLImageElement) => {
      if (img) {
        const aspectRatio = getAspectRatio(img.naturalWidth, img.naturalHeight)
        if (!Number.isNaN(aspectRatio)) {
          if (aspectRatio > 0) {
            const newHeight = node.data.props.width / aspectRatio
            setProp((props: ImageBlockProps) => (props.height = newHeight))
          } else {
            const newWidth = node.data.props.height * aspectRatio
            setProp((props: ImageBlockProps) => (props.width = newWidth))
          }
        }
      }
    },
    [node.data.props.height, node.data.props.width, setProp]
  )

  const handleLoad = useCallback(
    (event: React.SyntheticEvent<HTMLImageElement>) => {
      setAspectRatio(event.target as HTMLImageElement)
    },
    [setAspectRatio]
  )

  const imgConstrain =
    (maintainAspectRatio ? 'cover' : constraint) || ImageBlock.craft.defaultProps.constraint
  if (!src) {
    return (
      <div className={clazz} style={sty} ref={el => el && connect(drag(el as HTMLDivElement))} />
    )
  } else {
    return (
      <div className={clazz} style={sty} ref={el => el && connect(drag(el as HTMLDivElement))}>
        <Img
          display="inline-block"
          src={src || ImageBlock.craft.defaultProps.src}
          constrain={imgConstrain}
          onLoad={handleLoad}
        />
      </div>
    )
  }
}

ImageBlock.craft = {
  displayName: I18n.t('Image'),
  defaultProps: {
    src: '',
    width: EMPTY_IMAGE_WIDTH,
    height: EMPTY_IMAGE_HEIGHT,
    variant: 'default' as ImageVariant,
    constraint: 'cover' as ImageConstraint,
    maintainAspectRatio: true,
  },
  related: {
    toolbar: ImageBlockToolbar,
    resizer: BlockResizer,
  },
  custom: {
    isResizable: true,
  },
}

export {ImageBlock}
