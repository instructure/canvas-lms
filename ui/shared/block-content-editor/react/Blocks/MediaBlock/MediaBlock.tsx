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

import React, {useEffect, useState} from 'react'
import {MediaBlockSettings} from './MediaBlockSettings'
import {MediaEdit} from './MediaEdit'
import {MediaView} from './MediaView'
import {BaseBlock, useGetRenderMode} from '../BaseBlock'
import {MediaBlockProps, MediaData} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'
import {useSave} from '../BaseBlock/useSave'

const I18n = createI18nScope('block_content_editor')

const MediaContainer = (props: MediaData) => {
  const {isEditMode, isEditPreviewMode} = useGetRenderMode()

  const [title, setTitle] = useState(props.title)

  const save = useSave<typeof MediaBlock>()

  useEffect(() => {
    if (isEditPreviewMode) {
      save({title})
    }
  }, [isEditPreviewMode, title, save])

  return isEditMode ? (
    <MediaEdit {...props} onTitleChange={setTitle} title={title} />
  ) : (
    <MediaView {...props} title={title} />
  )
}

export const MediaBlock = (props: MediaBlockProps) => {
  return (
    <BaseBlock
      title={MediaBlock.craft.displayName}
      backgroundColor={props.backgroundColor}
      statefulProps={{
        src: props.src,
        title: props.title,
        backgroundColor: props.backgroundColor,
        titleColor: props.titleColor,
        includeBlockTitle: props.includeBlockTitle,
      }}
    >
      <MediaContainer {...props} />
    </BaseBlock>
  )
}

MediaBlock.craft = {
  displayName: I18n.t('Media'),
  related: {
    settings: MediaBlockSettings,
  },
}
