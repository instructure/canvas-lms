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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextBlockSettings} from './TextBlockSettings'
import {BaseBlock} from '../BaseBlock'
import {useSave} from '../BaseBlock/useSave'
import {TextBlockProps} from './types'
import {TextEditPreview} from '../BlockItems/Text/TextEditPreview'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {TextEdit} from '../BlockItems/Text/TextEdit'
import {useFocusElement} from '../../hooks/useFocusElement'
import {TextBlockLayout} from './TextBlockLayout'
import {TitleView} from '../BlockItems/Title/TitleView'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {TextView} from '../BlockItems/Text/TextView'
import {defaultProps} from './defaultProps'

const I18n = createI18nScope('block_content_editor')

const TextBlockView = (props: TextBlockProps) => {
  return (
    <TextBlockLayout
      title={
        props.includeBlockTitle &&
        !!props.title && <TitleView title={props.title} contentColor={props.titleColor} />
      }
      text={<TextView content={props.content} />}
    />
  )
}

const TextBlockEditView = (props: TextBlockProps) => {
  return (
    <TextBlockLayout
      title={
        props.includeBlockTitle && (
          <TitleEditPreview title={props.title} contentColor={props.titleColor} />
        )
      }
      text={<TextEditPreview content={props.content} />}
    />
  )
}

const TextBlockEdit = (props: TextBlockProps) => {
  const {focusHandler} = useFocusElement()
  const [title, setTitle] = useState(props.title)
  const [content, setContent] = useState(props.content)

  useSave<typeof TextBlock>(() => ({
    title,
    content,
  }))

  return (
    <TextBlockLayout
      title={
        props.includeBlockTitle && (
          <TitleEdit title={title} onTitleChange={setTitle} focusHandler={focusHandler} />
        )
      }
      text={
        <TextEdit
          content={content}
          onContentChange={setContent}
          height={300}
          focusHandler={props.includeBlockTitle && focusHandler}
        />
      }
    />
  )
}

export const TextBlock = (props: Partial<TextBlockProps>) => {
  const componentProps = {...defaultProps, ...props}
  return (
    <BaseBlock
      ViewComponent={TextBlockView}
      EditComponent={TextBlockEdit}
      EditViewComponent={TextBlockEditView}
      componentProps={componentProps}
      title={TextBlock.craft.displayName}
      backgroundColor={componentProps.backgroundColor}
    />
  )
}

TextBlock.craft = {
  displayName: I18n.t('Text column') as string,
  related: {
    settings: TextBlockSettings,
  },
}
