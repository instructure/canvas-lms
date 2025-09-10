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
import {MediaData, MediaSettings, MediaSources} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {SettingsUploadMedia} from '../BlockItems/SettingsUploadMedia/SettingsUploadMedia'
import {Flex} from '@instructure/ui-flex'
import {defaultProps} from './defaultProps'

const I18n = createI18nScope('block-editor')

export const MediaBlockSettings = () => {
  const {
    actions: {setProp},
    includeBlockTitle,
    titleColor,
    backgroundColor,
    src,
  } = useNode(node => ({
    ...defaultProps,
    ...node.data.props,
  }))

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

  const handleMediaChange = (data: MediaSources) => {
    setProp((props: MediaData) => {
      props.src = data.src
      props.mediaId = data.mediaId
      props.attachment_id = data.attachment_id
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
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        collapsedLabel={I18n.t('Expand color settings')}
        expandedLabel={I18n.t('Collapse color settings')}
        defaultExpanded={true}
        includeSeparator={true}
      >
        <Flex direction="column" gap="medium">
          <ColorPickerWrapper
            label={I18n.t('Background color')}
            popoverButtonScreenReaderLabel={I18n.t('Open background color picker popover')}
            value={backgroundColor}
            baseColor={titleColor}
            baseColorLabel={I18n.t('Title color')}
            onChange={handleBackgroundColorChange}
          />
          <ColorPickerWrapper
            label={I18n.t('Title color')}
            popoverButtonScreenReaderLabel={I18n.t('Open title color picker popover')}
            value={titleColor}
            baseColor={backgroundColor}
            baseColorLabel={I18n.t('Background color')}
            onChange={handleTitleColorChange}
          />
        </Flex>
      </SettingsSectionToggle>
      <SettingsSectionToggle
        title={I18n.t('Media settings')}
        collapsedLabel={I18n.t('Expand media settings')}
        expandedLabel={I18n.t('Collapse media settings')}
        defaultExpanded={true}
        includeSeparator={false}
      >
        <SettingsUploadMedia onMediaChange={handleMediaChange} url={src!} />
      </SettingsSectionToggle>
    </>
  )
}
