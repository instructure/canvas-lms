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

const isSeparatorLine = (element: Element): boolean => {
  return element.tagName.toLowerCase() === 'hr'
}

export const separatorLineContrast = {
  id: 'separator-line-contrast',

  test: (elem: Element): boolean => {
    if (!isSeparatorLine(elem)) {
      return true
    }

    if (!elem.parentElement) {
      return true
    }

    const parentBackgroundColor = getInheritedBackgroundColor(elem.parentElement)
    const hrColor = window.getComputedStyle(elem).borderColor

    return contrast(parentBackgroundColor, hrColor) >= 3
  },

  message: (): string =>
    I18n.t(
      'Separator line should have sufficient contrast with surrounding content (minimum 3:1 ratio).',
    ),

  why: (): string =>
    I18n.t(
      'Separator lines with poor contrast are difficult to distinguish from surrounding content, making them hard to see and reducing their effectiveness in organizing content, especially for users with low vision.',
    ),

  link: 'https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html',

  linkText: (): string => I18n.t('Learn more about UI component contrast'),
}
