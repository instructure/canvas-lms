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
import {TextBlockEdit} from './TextBlockEdit'
import {TextBlockEditPreview} from './TextBlockEditPreview'
import {TextBlockSettings} from './TextBlockSettings'
import {BaseBlock, useGetRenderMode} from '../BaseBlock'
import {useSave} from '../BaseBlock/useSave'
import {TextBlockProps} from './types'

export const TextBlockContent = (props: TextBlockProps) => {
  const {isEditMode, isEditPreviewMode} = useGetRenderMode()
  const save = useSave<typeof TextBlock>()

  const [title, setTitle] = useState(props.title)
  const [content, setContent] = useState(props.content)

  useEffect(() => {
    if (isEditPreviewMode) {
      save({
        title,
        content,
      })
    }
  }, [isEditPreviewMode, title, content, save])

  return isEditMode ? (
    <TextBlockEdit
      title={title}
      content={content}
      settings={props.settings}
      onTitleChange={(newTitle: string) => setTitle(newTitle)}
      onContentChange={(newContent: string) => setContent(newContent)}
    />
  ) : (
    <TextBlockEditPreview title={title} content={content} settings={props.settings} />
  )
}

const I18n = createI18nScope('block_content_editor')

export const TextBlock = (props: TextBlockProps) => {
  return (
    <BaseBlock<typeof TextBlock>
      title={TextBlock.craft.displayName}
      backgroundColor={props.settings.backgroundColor}
      statefulProps={{title: props.title, content: props.content}}
    >
      <TextBlockContent {...props} />
    </BaseBlock>
  )
}

TextBlock.craft = {
  displayName: I18n.t('Text column') as string,
  related: {
    settings: TextBlockSettings,
  },
}
