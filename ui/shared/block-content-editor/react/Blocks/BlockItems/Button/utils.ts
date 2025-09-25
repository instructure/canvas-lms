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

import {alpha, lighten, darken} from '@instructure/ui-color-utils'
import {BaseButtonTheme} from '@instructure/shared-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import tinyColor from 'tinycolor2'
import {ButtonBaseProps} from './types'

const I18n = createI18nScope('block_content_editor')

const BOX_SHADOW = 'inset 0 0 0.1875rem 0.0625rem'

export const getAdjustedColor = (color: string): string => {
  const tinyColorObj = tinyColor(color)
  const isLight = tinyColorObj.isLight()
  const luminosity = tinyColorObj.getLuminance()
  const baseAmount = 10

  if (isLight) {
    return darken(color, baseAmount)
  } else {
    const adjustedAmount = baseAmount + (0.5 - luminosity) * 20
    return lighten(color, adjustedAmount)
  }
}

export const getButtonText = (props: ButtonBaseProps): string => {
  return props.text.trim() || I18n.t('Button')
}

export const getButtonThemeOverride = (props: ButtonBaseProps) => {
  const adjustedPrimaryColor = getAdjustedColor(props.primaryColor)
  const adjustedBoxShadow = `${BOX_SHADOW} ${alpha(adjustedPrimaryColor, 28)}`

  const themeOverride = (): Partial<BaseButtonTheme> => {
    return {
      secondaryActiveBackground: adjustedPrimaryColor,
      secondaryActiveBoxShadow: adjustedBoxShadow,
      secondaryBackground: props.primaryColor,
      secondaryBorderColor: props.primaryColor,
      secondaryColor: props.secondaryColor,
      secondaryHoverBackground: adjustedPrimaryColor,
      secondaryGhostColor: props.primaryColor,
      secondaryGhostBorderColor: props.primaryColor,
      secondaryGhostHoverBackground: `${alpha(adjustedPrimaryColor, 10)}`,
      secondaryGhostActiveBoxShadow: adjustedBoxShadow,
    }
  }

  return themeOverride
}

export const getCommonButtonProps = (props: ButtonBaseProps) => {
  return {
    elementRef: (el: Element | null) => props.focusHandler?.(el as HTMLElement),
    display: props.isFullWidth ? 'block' : 'inline-block',
    withBackground: props.style === 'filled',
    themeOverride: getButtonThemeOverride(props),
    'data-button': true,
  } as const
}

export const getLinkProps = (props: ButtonBaseProps) => {
  const trimmedUrl = props.url.trim()
  const isNewTabLink = props.linkOpenMode === 'new-tab'

  return {
    href: trimmedUrl || undefined,
    target: isNewTabLink ? '_blank' : undefined,
    rel: isNewTabLink ? 'noopener noreferrer' : undefined,
    url: trimmedUrl,
    isNewTabLink,
  }
}
