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

import {useScope as createI18nScope} from '@canvas/i18n'
import {contrast} from '@instructure/ui-color-utils'
import {getInheritedBackgroundColor} from '../utils/backgroundUtils'

const I18n = createI18nScope('block_content_editor')

const isStandardButton = (element: Element): boolean => {
  return (
    element.tagName.toLowerCase() === 'button' ||
    element.getAttribute('role') === 'button' ||
    (element.tagName.toLowerCase() === 'input' &&
      ['button', 'submit', 'reset'].includes((element as HTMLInputElement).type))
  )
}

export const buttonBackgroundContrast = {
  id: 'button-background-contrast',

  test: (elem: Element): boolean => {
    if (!isStandardButton(elem)) {
      return true
    }

    const spanChild = elem.querySelector('span')
    if (!spanChild) {
      return true // Skip buttons because it is not InstUi structure
    }

    if (!elem.parentElement) {
      return true
    }

    const parentBackgroundColor = getInheritedBackgroundColor(elem.parentElement)
    // Border color is something that we can rely on in case of instui button
    const borderColor = window.getComputedStyle(spanChild).borderColor

    return contrast(parentBackgroundColor, borderColor) >= 3
  },

  message: (): string =>
    I18n.t(
      'Button background should have sufficient contrast with surrounding content (minimum 3:1 ratio).',
    ),

  why: (): string =>
    I18n.t(
      'Buttons with poor background contrast are difficult to distinguish from surrounding content, making them hard to locate and use, especially for users with low vision.',
    ),

  link: 'https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html',

  linkText: (): string => I18n.t('Learn more about UI component contrast'),
}
