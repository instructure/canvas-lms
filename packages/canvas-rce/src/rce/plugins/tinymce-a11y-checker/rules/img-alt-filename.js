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

const FILENAMELIKE = /[^\s]+(.*?).(jpg|jpeg|png|gif|svg|bmp|webp)$/i

export default {
  id: 'img-alt-filename',

  test: elem => {
    if (elem.tagName !== 'IMG') {
      return true
    }
    const alt = elem.hasAttribute('alt') ? elem.getAttribute('alt') : null
    const isDecorative = alt !== null && alt.replace(/\s/g, '') === ''
    return !FILENAMELIKE.test(alt) || isDecorative
  },

  data: elem => {
    const alt = elem.hasAttribute('alt') ? elem.getAttribute('alt') : null
    const decorative = alt !== null && alt.replace(/\s/g, '') === ''
    return {
      alt: alt || '',
      decorative,
    }
  },

  form: () => [
    {
      label: formatMessage('Change alt text'),
      dataKey: 'alt',
      disabledIf: data => data.decorative,
    },
    {
      label: formatMessage('Decorative image'),
      dataKey: 'decorative',
      checkbox: true,
    },
  ],

  update: (elem, data) => {
    if (data.decorative) {
      elem.setAttribute('alt', '')
      elem.setAttribute('role', 'presentation')
    } else {
      elem.setAttribute('alt', data.alt)
      elem.removeAttribute('role')
    }
    return elem
  },

  message: () =>
    formatMessage(
      'Image filenames should not be used as the alt attribute describing the image content.'
    ),

  why: () =>
    formatMessage(
      'Screen readers cannot determine what is displayed in an image without alternative text, and filenames are often meaningless strings of numbers and letters that do not describe the context or meaning.'
    ),

  link: 'https://www.w3.org/TR/WCAG20-TECHS/F30.html',
  linkText: () => formatMessage('Learn more about using filenames as alt text'),
}
