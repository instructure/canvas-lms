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

import React from 'react'
import {useNode} from '@craftjs/core'
import type {ImageBlockProps} from './types'
import {SettingsImageInfos} from '../BlockItems/SettingsImageInfos/SettingsImageInfos'
import {View} from '@instructure/ui-view'
import {SettingsUploadImage} from '../BlockItems/SettingsUploadImage/SettingsUploadImage'
import {ImageData} from '../BlockItems/Image/types'

export const ImageBlockSettings = () => {
  const {
    actions: {setProp},
    caption,
    altText,
    altTextAsCaption,
    decorativeImage,
    url,
    fileName,
  } = useNode(node => ({
    caption: node.data.props.caption,
    altText: node.data.props.altText,
    altTextAsCaption: node.data.props.altTextAsCaption,
    decorativeImage: node.data.props.decorativeImage,
    url: node.data.props.url,
    fileName: node.data.props.fileName,
  }))

  const handleCaptionChange = (caption: string) => {
    setProp((props: ImageBlockProps) => {
      props.caption = caption
    })
  }

  const handleAltTextChange = (altText: string) => {
    setProp((props: ImageBlockProps) => {
      props.altText = altText
    })
  }

  const handleAltTextAsCaptionChange = (newAltTextAsCaption: boolean) => {
    setProp((props: ImageBlockProps) => {
      props.altTextAsCaption = newAltTextAsCaption
      if (newAltTextAsCaption) {
        props.caption = props.altText
      }
    })
  }

  const handleDecorativeImageChange = (newDecorativeImage: boolean) => {
    setProp((props: ImageBlockProps) => {
      props.decorativeImage = newDecorativeImage
      if (newDecorativeImage) {
        props.altText = ''
        props.altTextAsCaption = false
        props.caption = ''
      }
    })
  }

  const handleImageDataChange = (imageData: ImageData) => {
    setProp((props: ImageBlockProps) => {
      props.url = imageData.url
      props.altText = imageData.altText
      props.fileName = imageData.fileName
      props.decorativeImage = imageData.decorativeImage
    })
  }

  return (
    <>
      <View as="div" margin="0 0 medium 0">
        <SettingsUploadImage
          onImageChange={handleImageDataChange}
          url={url || ''}
          fileName={fileName || ''}
        />
      </View>
      <View as="div">
        <SettingsImageInfos
          caption={caption}
          altText={altText}
          altTextAsCaption={altTextAsCaption}
          decorativeImage={decorativeImage}
          onCaptionChange={handleCaptionChange}
          onAltTextChange={handleAltTextChange}
          onAltTextAsCaptionChange={handleAltTextAsCaptionChange}
          onDecorativeImageChange={handleDecorativeImageChange}
        />
      </View>
    </>
  )
}
