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

import {BaseBlock} from '../BaseBlock'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ImageTextBlockSettings} from './ImageTextBlockSettings'
import {ImageTextBlockProps} from './types'
import {useSave} from '../BaseBlock/useSave'
import {useState} from 'react'
import {ImageTextBlockLayout} from './ImageTextBlockLayout'
import {TitleView} from '../BlockItems/Title/TitleView'
import {ImageEdit, ImageView} from '../BlockItems/Image'
import {TextView} from '../BlockItems/Text/TextView'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {TextEditPreview} from '../BlockItems/Text/TextEditPreview'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {TextEdit} from '../BlockItems/Text/TextEdit'
import {useFocusElement} from '../../hooks/useFocusElement'
import {defaultProps} from './defaultProps'
import {getContrastingTextColorCached} from '../../utilities/getContrastingTextColor'

const I18n = createI18nScope('block_content_editor')

const ImageTextBlockView = ({
  title,
  content,
  url,
  altText,
  decorativeImage,
  titleColor,
  includeBlockTitle,
  arrangement,
  textToImageRatio,
  caption,
  altTextAsCaption,
}: ImageTextBlockProps) => {
  return (
    <ImageTextBlockLayout
      titleComponent={
        includeBlockTitle && !!title && <TitleView title={title} contentColor={titleColor} />
      }
      imageComponent={
        <ImageView
          url={url}
          altText={altText}
          decorativeImage={decorativeImage}
          caption={caption}
          captionColor={titleColor}
          altTextAsCaption={altTextAsCaption}
        />
      }
      textComponent={<TextView content={content} />}
      arrangement={arrangement}
      textToImageRatio={textToImageRatio}
      dataTestId="imagetext-block-view"
    />
  )
}

const ImageTextBlockEditView = ({
  title,
  content,
  url,
  altText,
  decorativeImage,
  titleColor,
  arrangement,
  textToImageRatio,
  includeBlockTitle,
  caption,
  altTextAsCaption,
}: ImageTextBlockProps) => {
  return (
    <ImageTextBlockLayout
      titleComponent={
        includeBlockTitle && <TitleEditPreview title={title} contentColor={titleColor} />
      }
      imageComponent={
        <ImageView
          url={url}
          altText={altText}
          decorativeImage={decorativeImage}
          caption={caption}
          captionColor={titleColor}
          altTextAsCaption={altTextAsCaption}
        />
      }
      textComponent={<TextEditPreview content={content} />}
      arrangement={arrangement}
      textToImageRatio={textToImageRatio}
      dataTestId="imagetext-block-editpreview"
    />
  )
}

const ImageTextBlockEdit = (props: ImageTextBlockProps) => {
  const {focusHandler} = useFocusElement()
  const [title, setTitle] = useState(props.title)
  const [content, setContent] = useState(props.content)
  const labelColor = getContrastingTextColorCached(props.backgroundColor)

  const save = useSave(() => ({
    title,
    content,
  }))

  return (
    <ImageTextBlockLayout
      titleComponent={
        props.includeBlockTitle && (
          <TitleEdit
            title={title}
            onTitleChange={setTitle}
            focusHandler={focusHandler}
            labelColor={labelColor}
          />
        )
      }
      imageComponent={
        <ImageEdit
          {...props}
          captionColor={props.titleColor}
          onImageChange={data => save({...data})}
          focusHandler={!props.includeBlockTitle && focusHandler}
        />
      }
      textComponent={<TextEdit content={content} onContentChange={setContent} height={300} />}
      arrangement={props.arrangement}
      textToImageRatio={props.textToImageRatio}
      dataTestId="imagetext-block-edit"
    />
  )
}

export const ImageTextBlock = (props: Partial<ImageTextBlockProps>) => {
  const componentProps = {...defaultProps, ...props}
  return (
    <BaseBlock
      ViewComponent={ImageTextBlockView}
      EditComponent={ImageTextBlockEdit}
      EditViewComponent={ImageTextBlockEditView}
      componentProps={componentProps}
      title={ImageTextBlock.craft.displayName}
      backgroundColor={componentProps.backgroundColor}
    />
  )
}

ImageTextBlock.craft = {
  displayName: I18n.t('Image + text') as string,
  related: {
    settings: ImageTextBlockSettings,
  },
}
