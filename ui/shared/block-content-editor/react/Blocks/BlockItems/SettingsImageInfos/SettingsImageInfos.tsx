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

import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {ChangeEvent} from 'react'
import {SettingsImageProps} from './types'

const I18n = createI18nScope('block_content_editor')

export const SettingsImageInfos = ({
  altText,
  caption,
  decorativeImage,
  altTextAsCaption,
  disabled = false,
  onCaptionChange,
  onAltTextChange,
  onAltTextAsCaptionChange,
  onDecorativeImageChange,
}: SettingsImageProps) => {
  const handleAltTextChange = (e: ChangeEvent<HTMLInputElement>) => {
    onAltTextChange(e.target.value)
  }

  const handleDecorativeImageChange = (e: ChangeEvent<HTMLInputElement>) => {
    onDecorativeImageChange(e.target.checked)
    onAltTextAsCaptionChange(false)
  }

  const handleCaptionChange = (e: ChangeEvent<HTMLInputElement>) => {
    onCaptionChange(e.target.value)
  }

  const handleAltTextAsCaptionChange = (e: ChangeEvent<HTMLInputElement>) => {
    onAltTextAsCaptionChange(e.target.checked)
  }

  return (
    <>
      <View as="div" margin="0 0 medium 0">
        <TextInput
          renderLabel={
            <Text as="span">
              {I18n.t('Alt text')}
              <Tooltip
                renderTip={I18n.t('Used by screen readers to describe the content of an image')}
                placement="top start"
                on={['click', 'hover', 'focus']}
              >
                <IconButton
                  renderIcon={IconInfoLine}
                  withBackground={false}
                  withBorder={false}
                  screenReaderLabel={I18n.t('Alt text info')}
                  size="small"
                />
              </Tooltip>
            </Text>
          }
          value={altText}
          onChange={handleAltTextChange}
          placeholder={I18n.t('Start typing...')}
          disabled={disabled || decorativeImage}
        />

        <View as="div" margin="small 0 0 0">
          <Checkbox
            label={I18n.t('Decorative image')}
            checked={decorativeImage}
            disabled={disabled || altTextAsCaption}
            onChange={handleDecorativeImageChange}
          />
        </View>
      </View>
      <TextInput
        renderLabel={I18n.t('Image caption')}
        value={caption}
        onChange={handleCaptionChange}
        placeholder={I18n.t('Start typing...')}
        disabled={disabled || altTextAsCaption}
      />
      <View as="div" margin="small 0">
        <Checkbox
          label={I18n.t('Use alt text as caption')}
          checked={altTextAsCaption}
          onChange={handleAltTextAsCaptionChange}
          disabled={disabled || decorativeImage}
        />
      </View>
    </>
  )
}
