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

import {ImageTextBlockEditPreviewProps} from './types'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {ImageView} from '../BlockItems/Image'
import {TextEditPreview} from '../BlockItems/Text/TextEditPreview'
import {ImageTextBlockLayout} from './ImageTextBlockLayout'

export const ImageTextBlockEditPreview = ({
  title,
  content,
  url,
  altText,
  decorativeImage,
  textColor,
  arrangement,
  textToImageRatio,
  includeBlockTitle,
  caption,
  altTextAsCaption,
}: ImageTextBlockEditPreviewProps) => {
  return (
    <ImageTextBlockLayout
      titleComponent={<TitleEditPreview contentColor={textColor} title={title} />}
      imageComponent={
        <ImageView
          url={url}
          altText={altText}
          decorativeImage={decorativeImage}
          caption={caption}
          altTextAsCaption={altTextAsCaption}
        />
      }
      textComponent={<TextEditPreview contentColor={textColor} content={content} />}
      includeBlockTitle={includeBlockTitle}
      arrangement={arrangement}
      textToImageRatio={textToImageRatio}
      dataTestId="imagetext-block-editpreview"
    />
  )
}
