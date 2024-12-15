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

import React, {useCallback, useEffect, useState} from 'react'
import {useEditor, useNode} from '@craftjs/core'
import {MediaBlockToolbar} from './MediaBlockToolbar'
import {MediaBlockPreviewThumbnail} from './MediaBlockPreviewThumbnail'
import {useClassNames} from '../../../../utils'
import {type MediaBlockProps, type MediaVariant, type MediaConstraint} from './types'
import {BlockResizer} from '../../../editor/BlockResizer'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const MediaBlock = ({src, title, attachmentId}: MediaBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !src}, ['block', 'media-block'])

  if (!src) {
    return (
      <div
        role="treeitem"
        aria-label={MediaBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        ref={el => el && connect(drag(el as HTMLDivElement))}
      />
    )
  } else {
    return (
      <div
        role="treeitem"
        aria-label={MediaBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        style={{position: 'relative'}}
        ref={el => {
          el && connect(drag(el as HTMLDivElement))
        }}
      >
        {enabled ? (
          <MediaBlockPreviewThumbnail
            src={src || MediaBlock.craft.defaultProps.src}
            attachmentId={attachmentId}
            title={title || ''}
          />
        ) : (
          <iframe
            style={{
              width: '320px',
              height: '14.25rem',
              display: 'inline-block',
            }}
            title={title || ''}
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
    variant: 'default' as MediaVariant,
    constraint: 'cover' as MediaConstraint,
    maintainAspectRatio: false,
    sizeVariant: 'auto',
    title: '',
    attachmentId: '',
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
