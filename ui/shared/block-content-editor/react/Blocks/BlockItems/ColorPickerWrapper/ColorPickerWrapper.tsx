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

import {ColorPicker} from '@instructure/ui-color-picker'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

type ColorPickerWrapperProps = {
  label: string
  value: string
  baseColor: string
  onChange: (value: string) => void
  baseColorLabel: string
}

export const ColorPickerWrapper = ({
  label,
  value,
  baseColor,
  baseColorLabel,
  onChange,
}: ColorPickerWrapperProps) => {
  return (
    <ColorPicker
      label={label}
      placeholderText={I18n.t('Enter HEX')}
      value={value}
      onChange={onChange}
      withAlpha
      colorMixerSettings={{
        popoverAddButtonLabel: I18n.t('Apply'),
        popoverCloseButtonLabel: I18n.t('Close'),
        colorContrast: {
          firstColor: baseColor,
          label: I18n.t('Contrast Ratio'),
          successLabel: I18n.t('PASS'),
          failureLabel: I18n.t('FAIL'),
          normalTextLabel: I18n.t('Normal text'),
          largeTextLabel: I18n.t('Large text'),
          graphicsTextLabel: I18n.t('Graphics text'),
          firstColorLabel: baseColorLabel,
          secondColorLabel: label,
        },
        colorMixer: {
          withAlpha: true,
          rgbRedInputScreenReaderLabel: I18n.t('Input field for red'),
          rgbGreenInputScreenReaderLabel: I18n.t('Input field for green'),
          rgbBlueInputScreenReaderLabel: I18n.t('Input field for blue'),
          rgbAlphaInputScreenReaderLabel: I18n.t('Input field for alpha'),
          colorSliderNavigationExplanationScreenReaderLabel: I18n.t(
            `You are on a color slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
          ),
          alphaSliderNavigationExplanationScreenReaderLabel: I18n.t(
            `You are on an alpha slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
          ),
          colorPaletteNavigationExplanationScreenReaderLabel: I18n.t(
            `You are on a color palette. To navigate on the palette up, left, down or right, use the 'W', 'A', 'S' and 'D' buttons respectively`,
          ),
        },
      }}
    />
  )
}
