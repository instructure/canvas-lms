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

const MAX_ALT_LENGTH = 120

export default {
  'max-alt-length': MAX_ALT_LENGTH,
  id: 'img-alt-length',
  test: elem => {
    if (elem.tagName !== 'IMG') {
      return true
    }
    const alt = elem.getAttribute('alt')
    return alt == null || alt.length <= MAX_ALT_LENGTH
  },

  data: elem => {
    const alt = elem.getAttribute('alt')
    return {alt: alt || ''}
  },

  form: () => [
    {
      label: formatMessage('Change alt text'),
      dataKey: 'alt',
      textarea: true,
    },
  ],

  update: (elem, data) => {
    elem.setAttribute('alt', data.alt)
    return elem
  },

  message: () => formatMessage('Alt attribute text should not contain more than 120 characters.'),

  why: () =>
    formatMessage(
      'Screen readers cannot determine what is displayed in an image without alternative text, which describes the content and meaning of the image. Alternative text should be simple and concise.'
    ),

  link: '',
}
