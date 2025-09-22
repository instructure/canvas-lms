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
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {defaultProps} from './defaultProps'

const I18n = createI18nScope('block_content_editor')

export const ImageBlockSettings = () => {
  const {
    actions: {setProp},
    includeBlockTitle,
    backgroundColor,
    titleColor,
    caption,
    altText,
    altTextAsCaption,
    decorativeImage,
    url,
    fileName,
  } = useNode(node => ({
    ...defaultProps,
    ...node.data.props,
  }))

  const handleIncludeBlockTitleChange = () => {
    setProp((props: ImageBlockProps) => {
      props.includeBlockTitle = !includeBlockTitle
    })
  }

  const handleBackgroundColorChange = (color: string) => {
    setProp((props: ImageBlockProps) => {
      props.backgroundColor = color
    })
  }

  const handleTitleColorChange = (color: string) => {
    setProp((props: ImageBlockProps) => {
      props.titleColor = color
    })
  }

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
    })
  }

  const handleDecorativeImageChange = (newDecorativeImage: boolean) => {
    setProp((props: ImageBlockProps) => {
      props.decorativeImage = newDecorativeImage
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
    <View as="div">
      <SettingsIncludeTitle checked={includeBlockTitle} onChange={handleIncludeBlockTitleChange} />
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        collapsedLabel={I18n.t('Expand color settings')}
        expandedLabel={I18n.t('Collapse color settings')}
        defaultExpanded={true}
        includeSeparator={true}
      >
        <View as="div" margin="0 0 medium 0">
          <ColorPickerWrapper
            label={I18n.t('Background color')}
            popoverButtonScreenReaderLabel={I18n.t('Open background color picker popover')}
            value={backgroundColor}
            baseColor={titleColor}
            baseColorLabel={I18n.t('Title color')}
            onChange={handleBackgroundColorChange}
          />
        </View>
        <View as="div">
          <ColorPickerWrapper
            label={I18n.t('Title color')}
            popoverButtonScreenReaderLabel={I18n.t('Open title color picker popover')}
            value={titleColor}
            baseColor={backgroundColor}
            baseColorLabel={I18n.t('Background color')}
            onChange={handleTitleColorChange}
          />
        </View>
      </SettingsSectionToggle>
      <SettingsSectionToggle
        title={I18n.t('Image settings')}
        collapsedLabel={I18n.t('Expand image settings')}
        expandedLabel={I18n.t('Collapse image settings')}
        defaultExpanded={true}
        includeSeparator={false}
      >
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
            disabled={!url}
            altTextAsCaption={altTextAsCaption}
            decorativeImage={decorativeImage}
            imageUrl={url}
            fileName={fileName}
            onCaptionChange={handleCaptionChange}
            onAltTextChange={handleAltTextChange}
            onAltTextAsCaptionChange={handleAltTextAsCaptionChange}
            onDecorativeImageChange={handleDecorativeImageChange}
          />
        </View>
      </SettingsSectionToggle>
    </View>
  )
}
