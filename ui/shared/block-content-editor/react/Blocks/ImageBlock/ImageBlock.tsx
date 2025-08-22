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

import {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {BaseBlock, useGetRenderMode} from '../BaseBlock'
import {useSave} from '../BaseBlock/useSave'
import {ImageBlockSettings} from './ImageBlockSettings'
import {ImageEdit, ImageView} from '../BlockItems/Image'
import {ImageData} from '../BlockItems/Image/types'
import {ImageBlockProps} from './types'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {TitleView} from '../BlockItems/Title/TitleView'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'

const I18n = createI18nScope('block_content_editor')

const ImageContainer = (props: ImageBlockProps) => {
  const [title, setTitle] = useState(props.title || '')
  const {isEditMode, isViewMode, isEditPreviewMode} = useGetRenderMode()
  const save = useSave<typeof ImageBlock>()

  useEffect(() => {
    if (isEditPreviewMode) {
      save({
        title,
      })
    }
  }, [isEditPreviewMode, save, title])

  const onImageChange = (data: ImageData) => save(data)
  const onTitleChange = (newTitle: string) => setTitle(newTitle)

  return (
    <>
      {isEditMode && (
        <>
          {props.settings?.includeBlockTitle && (
            <TitleEdit title={title} onTitleChange={onTitleChange} />
          )}
          <ImageEdit {...props} onImageChange={onImageChange} />
        </>
      )}
      {isEditPreviewMode && (
        <>
          {props.settings?.includeBlockTitle && (
            <TitleEditPreview contentColor={props.settings?.textColor || ''} title={title} />
          )}
          <ImageView {...props} />
        </>
      )}
      {isViewMode && (
        <>
          {props.settings?.includeBlockTitle && (
            <TitleView contentColor={props.settings?.textColor || ''} title={title} />
          )}
          <ImageView {...props} />
        </>
      )}
    </>
  )
}

export const ImageBlock = (props: ImageBlockProps) => {
  return (
    <BaseBlock
      title={ImageBlock.craft.displayName}
      statefulProps={{title: props.title}}
      backgroundColor={props.settings?.backgroundColor}
    >
      <ImageContainer {...props} />
    </BaseBlock>
  )
}

ImageBlock.craft = {
  displayName: I18n.t('Full width image') as string,
  related: {
    settings: ImageBlockSettings,
  },
}
