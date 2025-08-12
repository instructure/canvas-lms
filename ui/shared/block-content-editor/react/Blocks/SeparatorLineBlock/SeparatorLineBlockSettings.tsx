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
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {SeparatorLineBlockProps} from './SeparatorLineBlock'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'

const I18n = createI18nScope('block_content_editor')

export const SeparatorLineBlockSettings = () => {
  const {
    actions: {setProp},
    settings,
  } = useNode(node => ({
    settings: node.data.props.settings,
  }))

  const handleSeparatorColorChange = (value: string) => {
    setProp((props: SeparatorLineBlockProps) => {
      props.settings.separatorColor = value
    })
  }

  const handleBackgroundColorChange = (value: string) => {
    setProp((props: SeparatorLineBlockProps) => {
      props.settings.backgroundColor = value
    })
  }

  return (
    <View as="div" padding="small">
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        collapsedLabel={I18n.t('Expand color settings')}
        expandedLabel={I18n.t('Collapse color settings')}
        defaultExpanded={true}
        includeSeparator={true}
      >
        <ColorPickerWrapper
          label={I18n.t('Background')}
          value={settings.backgroundColor}
          baseColor={settings.separatorColor}
          onChange={handleBackgroundColorChange}
          baseColorLabel={I18n.t('Background')}
        />
      </SettingsSectionToggle>
      <ColorPickerWrapper
        label={I18n.t('Separator')}
        value={settings.separatorColor}
        baseColor={settings.backgroundColor}
        onChange={handleSeparatorColorChange}
        baseColorLabel={I18n.t('Background')}
      />
    </View>
  )
}
