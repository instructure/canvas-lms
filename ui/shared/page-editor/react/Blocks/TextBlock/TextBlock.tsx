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
import {BaseBlock, useIsEditMode} from '../BaseBlock'
import {useSave} from '../BaseBlock/useSave'

export type TextBlockProps = {
  title: string
  content: string
}

export const TextBlockContent = (props: TextBlockProps) => {
  const isEditMode = useIsEditMode()
  const save = useSave<typeof TextBlock>()

  const [title, setTitle] = useState(props.title)
  const [content, setContent] = useState(props.content)

  useEffect(() => {
    if (!isEditMode) {
      save({
        title,
        content,
      })
    }
  }, [isEditMode, title, content, save])

  return isEditMode ? (
    <TextBlockEdit
      title={title}
      content={content}
      onTitleChange={(newTitle: string) => setTitle(newTitle)}
      onContentChange={(newContent: string) => setContent(newContent)}
    />
  ) : (
    <TextBlockEditPreview title={title} content={content} />
  )
}

const I18n = createI18nScope('page_editor')

export const TextBlock = (props: TextBlockProps) => {
  return (
    <BaseBlock title={I18n.t('Text Block')}>
      <TextBlockContent {...props} />
    </BaseBlock>
  )
}
