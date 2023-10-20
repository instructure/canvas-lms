/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import formatMessage from '../../../../format-message'
import contrast from 'wcag-element-contrast'
import {onlyContainsLink, createStyleString, splitStyleAttribute, hasTextNode} from '../utils/dom'
import rgbHex from '../utils/rgb-hex'
import {stringifyRGBA} from '../utils/colors'
import uid from '@instructure/uid'

export default {
  id: 'small-text-contrast',
  test: (elem, config = {}) => {
    const disabled = config.disableContrastCheck == true
    const noText = !hasTextNode(elem)

    if (disabled || noText || onlyContainsLink(elem) || contrast.isLargeText(elem)) {
      return true
    }
    for (let e = elem; e; e = e.parentElement) {
      const bgimage = window.getComputedStyle(e).getPropertyValue('background-image')
      if (bgimage !== 'none' && bgimage !== '') {
        // ignore background images and gradients
        return true
      }
    }
    return contrast(elem)
  },

  data: elem => {
    const styles = window.getComputedStyle(elem)
    return {
      color: stringifyRGBA(contrast.parseRGBA(styles.color)),
      id: uid(),
    }
  },

  form: () => [
    {
      label: formatMessage('Change text color'),
      dataKey: 'color',
      color: true,
    },
  ],

  update: (elem, data) => {
    elem.style.color = data.color
    const styles = splitStyleAttribute(elem.getAttribute('data-mce-style') || '')
    if (data && data.color && data.color.indexOf('#') < 0) {
      styles.color = `#${rgbHex(data.color)}`
    } else {
      styles.color = data.color
    }
    elem.setAttribute('data-mce-style', createStyleString(styles))
    return elem
  },

  message: () =>
    formatMessage(
      'Text smaller than 18pt (or bold 14pt) should display a minimum contrast ratio of 4.5:1.'
    ),

  why: () =>
    formatMessage(
      'Text is difficult to read without sufficient contrast between the text and the background, especially for those with low vision.'
    ),

  link: 'https://www.w3.org/TR/WCAG20-TECHS/G17.html',
  linkText: () => formatMessage('Learn more about color contrast'),
}
