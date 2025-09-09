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

import {useNode} from '@craftjs/core'
import {ArrangementOption, ImageTextBlockProps, TextToImageRatioOption} from './types'
import {ImageData} from '../BlockItems/Image/types'
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {SettingsUploadImage} from '../BlockItems/SettingsUploadImage/SettingsUploadImage'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Flex, FlexItem} from '@instructure/ui-flex'
import React, {ReactNode} from 'react'
import {SettingsImageInfos} from '../BlockItems/SettingsImageInfos/SettingsImageInfos'
import {defaultProps} from './defaultProps'

const I18n = createI18nScope('block_content_editor')

const TextToImageRatioLabel = ({
  mainLabel,
  secondaryLabel,
}: {mainLabel: string; secondaryLabel: string}) => {
  return (
    <Flex direction="column">
      <FlexItem>
        <Text>{mainLabel}</Text>
      </FlexItem>
      <FlexItem>
        <Text color="secondary">{secondaryLabel}</Text>
      </FlexItem>
    </Flex>
  )
}

const ARRANGEMENT_OPTIONS: {label: string; value: ArrangementOption}[] = [
  {label: I18n.t('Image on the left'), value: 'left'},
  {label: I18n.t('Image on the right'), value: 'right'},
]

const TEXT_TO_IMAGE_RATIO_OPTIONS: {label: ReactNode; value: TextToImageRatioOption}[] = [
  {
    label: (
      <TextToImageRatioLabel
        mainLabel={I18n.t('1:1')}
        secondaryLabel={I18n.t('Equal image and text space')}
      />
    ),
    value: '1:1',
  },
  {
    label: (
      <TextToImageRatioLabel
        mainLabel={I18n.t('2:1')}
        secondaryLabel={I18n.t('Text twice as big as image')}
      />
    ),
    value: '2:1',
  },
]

export const ImageTextBlockSettings = () => {
  const {
    actions: {setProp},
    includeBlockTitle,
    backgroundColor,
    titleColor,
    arrangement,
    textToImageRatio,
    url,
    fileName,
    altText,
    caption,
    altTextAsCaption,
    decorativeImage,
  } = useNode(node => ({
    ...defaultProps,
    ...node.data.props,
  }))

  const handleIncludeBlockTitleChange = () => {
    setProp((props: ImageTextBlockProps) => {
      props.includeBlockTitle = !includeBlockTitle
    })
  }

  const handleBackgroundColorChange = (color: string) => {
    setProp((props: ImageTextBlockProps) => {
      props.backgroundColor = color
    })
  }

  const handleTitleColorChange = (color: string) => {
    setProp((props: ImageTextBlockProps) => {
      props.titleColor = color
    })
  }

  const handleArrangementChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    const arrangement = value as ArrangementOption
    setProp((props: ImageTextBlockProps) => {
      props.arrangement = arrangement
    })
  }

  const handleTextToImageRatioChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    const textToImageRatio = value as TextToImageRatioOption
    setProp((props: ImageTextBlockProps) => {
      props.textToImageRatio = textToImageRatio
    })
  }

  const handleImageDataChange = (imageData: ImageData) => {
    setProp((props: ImageTextBlockProps) => {
      props.url = imageData.url
      props.altText = imageData.altText
      props.fileName = imageData.fileName
    })
  }

  const handleCaptionChange = (caption: string) => {
    setProp((props: ImageTextBlockProps) => {
      props.caption = caption
    })
  }

  const handleAltTextChange = (altText: string) => {
    setProp((props: ImageTextBlockProps) => {
      props.altText = altText
    })
  }

  const handleAltTextAsCaptionChange = (newAltTextAsCaption: boolean) => {
    setProp((props: ImageTextBlockProps) => {
      props.altTextAsCaption = newAltTextAsCaption
    })
  }

  const handleDecorativeImageChange = (newDecorativeImage: boolean) => {
    setProp((props: ImageTextBlockProps) => {
      props.decorativeImage = newDecorativeImage
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
            value={backgroundColor}
            baseColor={titleColor}
            baseColorLabel={I18n.t('Title color')}
            onChange={handleBackgroundColorChange}
          />
        </View>
        <View as="div">
          <ColorPickerWrapper
            label={I18n.t('Title color')}
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
          <RadioInputGroup
            name="image-text-element-arrangement"
            description={I18n.t('Element arrangement')}
            value={arrangement}
            onChange={handleArrangementChange}
          >
            {ARRANGEMENT_OPTIONS.map(option => (
              <RadioInput key={option.value} label={option.label} value={option.value} />
            ))}
          </RadioInputGroup>
        </View>
        <View as="div" margin="0 0 medium 0">
          <RadioInputGroup
            name="image-text-text-to-image-ratio"
            description={I18n.t('Text to image ratio')}
            value={textToImageRatio}
            onChange={handleTextToImageRatioChange}
          >
            {TEXT_TO_IMAGE_RATIO_OPTIONS.map(option => (
              <RadioInput key={option.value} label={option.label} value={option.value} />
            ))}
          </RadioInputGroup>
        </View>
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
