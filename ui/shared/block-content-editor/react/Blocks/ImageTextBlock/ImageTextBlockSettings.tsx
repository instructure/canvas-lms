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
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {ReactNode} from 'react'

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
    textColor,
    arrangement,
    textToImageRatio,
  } = useNode(node => ({
    includeBlockTitle: node.data.props.settings.includeBlockTitle,
    backgroundColor: node.data.props.settings.backgroundColor,
    textColor: node.data.props.settings.textColor,
    arrangement: node.data.props.settings.arrangement,
    textToImageRatio: node.data.props.settings.textToImageRatio,
  }))

  const handleIncludeBlockTitleChange = () => {
    setProp((props: ImageTextBlockProps) => {
      props.settings.includeBlockTitle = !includeBlockTitle
    })
  }

  const handleBackgroundColorChange = (color: string) => {
    setProp((props: ImageTextBlockProps) => {
      props.settings.backgroundColor = color
    })
  }

  const handleTextColorChange = (color: string) => {
    setProp((props: ImageTextBlockProps) => {
      props.settings.textColor = color
    })
  }

  const handleArrangementChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    const arrangement = value as ArrangementOption
    setProp((props: ImageTextBlockProps) => {
      props.settings.arrangement = arrangement
    })
  }

  const handleTextToImageRatioChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    const textToImageRatio = value as TextToImageRatioOption
    setProp((props: ImageTextBlockProps) => {
      props.settings.textToImageRatio = textToImageRatio
    })
  }

  return (
    <View as="div">
      <View as="div" margin="medium 0 medium 0">
        <SettingsIncludeTitle
          checked={includeBlockTitle}
          onChange={handleIncludeBlockTitleChange}
        />
      </View>
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        collapsedLabel={I18n.t('Expand color settings')}
        expandedLabel={I18n.t('Collapse color settings')}
        defaultExpanded={false}
        includeSeparator={true}
      >
        <View as="div" margin="0 0 medium 0">
          <ColorPickerWrapper
            label={I18n.t('Background color')}
            value={backgroundColor}
            baseColor={textColor}
            baseColorLabel={I18n.t('Default text color')}
            onChange={handleBackgroundColorChange}
          />
        </View>
        <View as="div">
          <ColorPickerWrapper
            label={I18n.t('Default text color')}
            value={textColor}
            baseColor={backgroundColor}
            baseColorLabel={I18n.t('Background color')}
            onChange={handleTextColorChange}
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
        <View as="div">
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
      </SettingsSectionToggle>
    </View>
  )
}
