/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

export const getColorMixerSettings = (backgroundColor: string, suggestedColors: string[]) => ({
  popoverAddButtonLabel: I18n.t('Select'),
  popoverCloseButtonLabel: I18n.t('Close'),
  colorMixer: {
    rgbRedInputScreenReaderLabel: I18n.t('Input field for red'),
    rgbGreenInputScreenReaderLabel: I18n.t('Input field for green'),
    rgbBlueInputScreenReaderLabel: I18n.t('Input field for blue'),
    rgbAlphaInputScreenReaderLabel: I18n.t('Input field for alpha'),
    colorSliderNavigationExplanationScreenReaderLabel: I18n.t(
      'Use left and right arrows to adjust color.',
    ),
    alphaSliderNavigationExplanationScreenReaderLabel: I18n.t(
      'Use left and right arrows to adjust alpha.',
    ),
    colorPaletteNavigationExplanationScreenReaderLabel: I18n.t(
      'Use arrow keys to navigate the color palette.',
    ),
    withAlpha: false,
  },
  colorPreset: {
    label: I18n.t('Suggested colors'),
    colors: suggestedColors,
  },
  colorContrast: {
    label: I18n.t('Contrast Ratio'),
    firstColorLabel: I18n.t('Background'),
    secondColorLabel: I18n.t('Foreground'),
    normalTextLabel: I18n.t('NORMAL TEXT'),
    largeTextLabel: I18n.t('LARGE TEXT'),
    graphicsTextLabel: I18n.t('GRAPHICS TEXT'),
    successLabel: I18n.t('PASS'),
    failureLabel: I18n.t('FAIL'),
    firstColor: backgroundColor,
  },
})
