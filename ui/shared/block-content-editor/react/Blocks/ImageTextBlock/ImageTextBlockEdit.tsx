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

import {ImageTextBlockEditProps} from './types'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {ImageEdit} from '../BlockItems/Image'
import {TextEdit} from '../BlockItems/Text/TextEdit'
import {ImageTextBlockLayout} from './ImageTextBlockLayout'

export const ImageTextBlockEdit = ({
  title,
  content,
  onContentChange,
  onTitleChange,
  onImageChange,
  url,
  altText,
  decorativeImage,
  arrangement,
  textToImageRatio,
  includeBlockTitle,
  caption,
  altTextAsCaption,
}: ImageTextBlockEditProps) => {
  return (
    <ImageTextBlockLayout
      titleComponent={<TitleEdit title={title} onTitleChange={onTitleChange} />}
      imageComponent={
        <ImageEdit
          onImageChange={onImageChange}
          url={url}
          altText={altText}
          caption={caption}
          altTextAsCaption={altTextAsCaption}
          decorativeImage={decorativeImage}
        />
      }
      textComponent={<TextEdit content={content} onContentChange={onContentChange} height={300} />}
      includeBlockTitle={includeBlockTitle}
      arrangement={arrangement}
      textToImageRatio={textToImageRatio}
      dataTestId="imagetext-block-edit"
    />
  )
}
