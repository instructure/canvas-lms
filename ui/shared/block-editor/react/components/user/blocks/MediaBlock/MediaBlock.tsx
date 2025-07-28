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
import {useEditor, useNode} from '@craftjs/core'
import {MediaBlockToolbar} from './MediaBlockToolbar'
import {MediaBlockPreviewThumbnail} from './MediaBlockPreviewThumbnail'
import {useClassNames} from '../../../../utils'
import {type MediaBlockProps} from './types'
import {BlockResizer} from '../../../editor/BlockResizer'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const MediaBlock = ({src, title, height = '50', width = '50', attachmentId}: MediaBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !src}, ['block', 'media-block'])
  const [dynamicHeight, setDynamicHeight] = useState<string>(height)
  const [dynamicWidth, setDynamicWidth] = useState(width)
  const [blockRef, setBlockRef] = useState<HTMLDivElement | null>(null)

  useEffect(() => {
    if (!blockRef) return

    setDynamicWidth(`${width}px`)
    setDynamicHeight(`${height}px`)
  }, [width, height, blockRef])

  if (!src) {
    return (
      <div
        role="treeitem"
        aria-label={MediaBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        ref={el => {
          el && connect(drag(el as HTMLDivElement))
          setBlockRef(el)
        }}
        style={{
          width: dynamicWidth,
          height: dynamicHeight,
          position: 'relative',
        }}
      />
    )
  } else {
    return (
      <div
        role="treeitem"
        aria-label={MediaBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        style={{
          width: dynamicWidth,
          height: dynamicHeight,
          position: 'relative',
        }}
        ref={el => {
          el && connect(drag(el as HTMLDivElement))
          setBlockRef(el)
        }}
      >
        {enabled ? (
          <MediaBlockPreviewThumbnail
            src={src || MediaBlock.craft.defaultProps.src}
            attachmentId={attachmentId}
            title={title || ''}
            onThumbnailLoad={() => {
              if (blockRef && blockRef.querySelector('img.media_thumbnail')) {
                const thumbnail = blockRef.querySelector('img.media_thumbnail') as HTMLImageElement
                setDynamicHeight(`${thumbnail.naturalHeight.toString()}px`)
                setDynamicWidth(`${thumbnail.naturalWidth.toString()}px`)
              }
            }}
          />
        ) : (
          <iframe
            style={{
              width: '100%',
              height: '100%',
              display: 'inline-block',
              objectFit: 'cover',
            }}
            title={title || ''}
            data-media-type="video"
            allow="fullscreen"
            src={src || MediaBlock.craft.defaultProps.src}
          />
        )}
      </div>
    )
  }
}

MediaBlock.craft = {
  displayName: I18n.t('Media'),
  defaultProps: {
    src: '',
    height: 150,
    width: 200,
    title: '',
    attachmentId: '',
    maintainAspectRatio: true,
  },
  related: {
    toolbar: MediaBlockToolbar,
    resizer: BlockResizer,
  },
  custom: {
    isResizable: true,
    isBlock: true,
  },
}

export {MediaBlock}
