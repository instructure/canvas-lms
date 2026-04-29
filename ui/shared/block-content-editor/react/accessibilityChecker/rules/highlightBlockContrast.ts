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

const hasBackgroundColor = (element: Element): boolean => {
  const style = window.getComputedStyle(element)
  const backgroundColor = style.backgroundColor
  return (
    !!backgroundColor && backgroundColor !== 'rgba(0, 0, 0, 0)' && backgroundColor !== 'transparent'
  )
}

const isHighlightBlock = (element: Element): boolean => {
  return element.tagName.toLowerCase() === 'span' && hasBackgroundColor(element)
}

export const highlightBlockContrast = {
  id: 'highlight-block-contrast',

  test: (elem: Element): boolean => {
    if (!isHighlightBlock(elem)) {
      return true
    }

    if (!elem.parentElement) {
      return true
    }

    const parentBackgroundColor = getInheritedBackgroundColor(elem.parentElement)
    const highlightBackgroundColor = window.getComputedStyle(elem).backgroundColor

    return contrast(parentBackgroundColor, highlightBackgroundColor) >= 3
  },

  message: (): string =>
    I18n.t(
      'Highlight color should have sufficient contrast with background color (minimum 3:1 ratio).',
    ),

  why: (): string =>
    I18n.t(
      'Highlight color with background colors that have poor contrast with their parent are difficult to distinguish, making highlighted content harder to read and less accessible for users with low vision.',
    ),

  link: 'https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html',

  linkText: (): string => I18n.t('Learn more about UI component contrast'),
}
