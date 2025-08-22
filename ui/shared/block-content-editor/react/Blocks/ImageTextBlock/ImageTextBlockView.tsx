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

import {ImageTextBlockViewProps} from './types'
import {TitleView} from '../BlockItems/Title/TitleView'
import {ImageView} from '../BlockItems/Image'
import {TextView} from '../BlockItems/Text/TextView'
import {ImageTextBlockLayout} from './ImageTextBlockLayout'

export const ImageTextBlockView = ({
  title,
  content,
  url,
  altText,
  decorativeImage,
  textColor,
  includeBlockTitle,
  arrangement,
  textToImageRatio,
  caption,
  altTextAsCaption,
}: ImageTextBlockViewProps) => {
  return (
    <ImageTextBlockLayout
      titleComponent={<TitleView contentColor={textColor} title={title} />}
      imageComponent={
        <ImageView
          url={url}
          altText={altText}
          decorativeImage={decorativeImage}
          caption={caption}
          altTextAsCaption={altTextAsCaption}
        />
      }
      textComponent={<TextView contentColor={textColor} content={content} />}
      includeBlockTitle={includeBlockTitle}
      arrangement={arrangement}
      textToImageRatio={textToImageRatio}
      dataTestId="imagetext-block-view"
    />
  )
}
