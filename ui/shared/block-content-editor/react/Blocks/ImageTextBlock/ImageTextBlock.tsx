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

import {BaseBlock, useGetRenderMode} from '../BaseBlock'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ImageTextBlockSettings} from './ImageTextBlockSettings'
import {Flex} from '@instructure/ui-flex'
import {ImageTextBlockEdit} from './ImageTextBlockEdit'
import {ImageTextBlockEditPreview} from './ImageTextBlockEditPreview'
import {ImageTextBlockProps} from './types'
import {useSave} from '../BaseBlock/useSave'
import {ImageData} from '../BlockItems/Image/types'
import {useEffect, useState} from 'react'
import {ImageTextBlockView} from './ImageTextBlockView'

const I18n = createI18nScope('block_content_editor')

const ImageTextContent = (props: ImageTextBlockProps) => {
  const {isEditMode, isEditPreviewMode, isViewMode} = useGetRenderMode()
  const save = useSave<typeof ImageTextBlock>()
  const [title, setTitle] = useState(props.title)
  const [content, setContent] = useState(props.content)
  const [url, setUrl] = useState(props.url)
  const [altText, setAltText] = useState(props.altText)
  const [fileName, setFileName] = useState(props.fileName)
  const [decorativeImage, setDectorativeImage] = useState(props.decorativeImage)

  useEffect(() => {
    if (isEditPreviewMode) {
      save({
        title,
        content,
        url,
        altText,
        fileName,
        decorativeImage,
      })
    }
  }, [altText, content, decorativeImage, fileName, isEditPreviewMode, save, title, url])

  useEffect(() => {
    setUrl(props.settings.url)
  }, [props.settings.url])

  useEffect(() => {
    setAltText(props.settings.altText)
  }, [props.settings.altText])

  useEffect(() => {
    setFileName(props.settings.fileName)
  }, [props.settings.fileName])

  useEffect(() => {
    setDectorativeImage(props.settings.decorativeImage)
  }, [props.settings.decorativeImage])

  useEffect(() => {
    if (url || altText || fileName || decorativeImage) {
      let captionSetting = props.settings.caption
      let calculatedAltText = altText

      if (decorativeImage) {
        calculatedAltText = ''
        captionSetting = ''
        setAltText(calculatedAltText)
      }

      save({
        settings: {
          ...props.settings,
          url,
          altText: calculatedAltText,
          fileName,
          decorativeImage,
          caption: captionSetting,
        },
      })
    }
    // NOTE: props.settings is excluded for prevent infinity loop
  }, [altText, fileName, save, url, decorativeImage])

  const onTitleChange = (newTitle: string) => setTitle(newTitle)
  const onContentChange = (newContent: string) => setContent(newContent)

  const onImageChange = (imageData: ImageData) => {
    setUrl(imageData.url)
    setAltText(imageData.altText)
    setFileName(imageData.fileName)
    setDectorativeImage(imageData.decorativeImage)
  }

  return (
    <Flex direction="column" gap="mediumSmall">
      {isEditMode && (
        <ImageTextBlockEdit
          title={title}
          content={content}
          url={url}
          altText={altText}
          includeBlockTitle={props.settings.includeBlockTitle}
          textColor={props.settings.textColor}
          arrangement={props.settings.arrangement}
          textToImageRatio={props.settings.textToImageRatio}
          decorativeImage={props.settings.decorativeImage}
          altTextAsCaption={props.settings.altTextAsCaption}
          caption={props.settings.caption}
          onTitleChange={onTitleChange}
          onContentChange={onContentChange}
          onImageChange={onImageChange}
        />
      )}
      {isEditPreviewMode && (
        <ImageTextBlockEditPreview
          title={title}
          content={content}
          url={url}
          altText={altText}
          textColor={props.settings.textColor}
          arrangement={props.settings.arrangement}
          textToImageRatio={props.settings.textToImageRatio}
          includeBlockTitle={props.settings.includeBlockTitle}
          decorativeImage={props.settings.decorativeImage}
          altTextAsCaption={props.settings.altTextAsCaption}
          caption={props.settings.caption}
        />
      )}
      {isViewMode && (
        <ImageTextBlockView
          title={title}
          content={content}
          url={url}
          altText={altText}
          textColor={props.settings.textColor}
          arrangement={props.settings.arrangement}
          textToImageRatio={props.settings.textToImageRatio}
          includeBlockTitle={props.settings.includeBlockTitle}
          decorativeImage={props.settings.decorativeImage}
          altTextAsCaption={props.settings.altTextAsCaption}
          caption={props.settings.caption}
        />
      )}
    </Flex>
  )
}

export const ImageTextBlock = (props: ImageTextBlockProps) => {
  return (
    <BaseBlock<typeof ImageTextBlock>
      title={ImageTextBlock.craft.displayName}
      backgroundColor={props.settings.backgroundColor}
      statefulProps={{
        title: props.title,
        content: props.content,
        url: props.url,
        altText: props.altText,
        fileName: props.fileName,
        decorativeImage: props.decorativeImage,
      }}
    >
      <ImageTextContent {...props} />
    </BaseBlock>
  )
}

ImageTextBlock.craft = {
  displayName: I18n.t('Image + text block') as string,
  related: {
    settings: ImageTextBlockSettings,
  },
}
