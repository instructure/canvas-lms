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
import {View} from '@instructure/ui-view'
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'
import {Text} from '@instructure/ui-text'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {MediaSettings} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export const MediaBlockSettings = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))

  const includeBlockTitle = props.includeBlockTitle !== false

  const handleIncludeBlockTitleChange = () => {
    setProp((props: MediaSettings) => {
      props.includeBlockTitle = !includeBlockTitle
    })
  }

  const handleBackgroundColorChange = (color: string) => {
    setProp((props: MediaSettings) => {
      props.backgroundColor = color
    })
  }

  const handleTitleColorChange = (color: string) => {
    setProp((props: MediaSettings) => {
      props.titleColor = color
    })
  }

  return (
    <>
      <View as="div" margin="0 0 medium 0">
        <Text size="medium" weight="bold">
          {I18n.t('Media Settings')}
        </Text>
      </View>

      <SettingsIncludeTitle checked={includeBlockTitle} onChange={handleIncludeBlockTitleChange} />

      <View as="div" margin="0 0 medium 0">
        <ColorPickerWrapper
          label={I18n.t('Background Color')}
          value={props.backgroundColor}
          baseColor={props.titleColor}
          baseColorLabel={I18n.t('Title Color')}
          onChange={handleBackgroundColorChange}
        />
      </View>

      <View as="div" margin="0 0 medium 0">
        <ColorPickerWrapper
          label={I18n.t('Title Color')}
          value={props.titleColor}
          baseColor={props.backgroundColor}
          baseColorLabel={I18n.t('Background Color')}
          onChange={handleTitleColorChange}
        />
      </View>
    </>
  )
}
