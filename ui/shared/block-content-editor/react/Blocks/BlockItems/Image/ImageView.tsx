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

import './image-block.css'
import {ImageViewProps} from './types'
import {DefaultPreviewImage} from '../DefaultPreviewImage/DefaultPreviewImage'
import {ImageCaption} from './ImageCaption'
import {View} from '@instructure/ui-view'

export const ImageView = ({
  url,
  altText,
  decorativeImage,
  altTextAsCaption,
  caption,
}: ImageViewProps) => {
  const calculatedCaption = altTextAsCaption ? altText : caption

  return (
    <View as="figure" margin="none">
      {url ? (
        <img
          width="100%"
          src={url}
          alt={decorativeImage ? '' : altText}
          role={decorativeImage ? 'presentation' : undefined}
        />
      ) : (
        <DefaultPreviewImage blockType="image" />
      )}
      {!!calculatedCaption && (
        <View as="figcaption" margin="mediumSmall 0 0 0">
          <ImageCaption>{calculatedCaption}</ImageCaption>
        </View>
      )}
    </View>
  )
}
