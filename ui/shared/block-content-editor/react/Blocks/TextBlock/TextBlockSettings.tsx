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
import {TextBlockProps} from './types'
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

export const TextBlockSettings = () => {
  const {
    actions: {setProp},
    includeBlockTitle,
    backgroundColor,
  } = useNode(node => ({
    includeBlockTitle: node.data.props.settings.includeBlockTitle,
    backgroundColor: node.data.props.settings.backgroundColor,
  }))

  const handleIncludeBlockTitleChange = () => {
    setProp((props: TextBlockProps) => {
      props.settings.includeBlockTitle = !includeBlockTitle
    })
  }

  const handleBackgroundColorChange = (color: string) => {
    setProp((props: TextBlockProps) => {
      props.settings.backgroundColor = color
    })
  }

  return (
    <>
      <SettingsIncludeTitle checked={includeBlockTitle} onChange={handleIncludeBlockTitleChange} />
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        collapsedLabel={I18n.t('Expand color settings')}
        expandedLabel={I18n.t('Collapse color settings')}
        defaultExpanded={false}
        includeSeparator={true}
      >
        <ColorPickerWrapper
          label={I18n.t('Background')}
          value={backgroundColor}
          baseColor="#000000" // Temporary base color
          baseColorLabel={I18n.t('Text')}
          onChange={handleBackgroundColorChange}
        />
      </SettingsSectionToggle>
    </>
  )
}
