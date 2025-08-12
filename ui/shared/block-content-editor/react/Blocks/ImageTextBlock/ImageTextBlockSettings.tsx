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
import {ImageTextBlockProps} from './types'
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('block_content_editor')

export const ImageTextBlockSettings = () => {
  const {
    actions: {setProp},
    includeBlockTitle,
    backgroundColor,
    textColor,
  } = useNode(node => ({
    includeBlockTitle: node.data.props.settings.includeBlockTitle,
    backgroundColor: node.data.props.settings.backgroundColor,
    textColor: node.data.props.settings.textColor,
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
        defaultExpanded={true}
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
        defaultExpanded={false}
        includeSeparator={false}
      >
        <div>Image settings</div>
      </SettingsSectionToggle>
    </View>
  )
}
