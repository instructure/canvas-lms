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
import {prepend} from '../utils/dom'

export default {
  id: 'table-caption',
  test: elem => {
    if (elem.tagName !== 'TABLE') {
      return true
    }
    const caption = elem.querySelector('caption')
    return !!caption && caption.textContent.replace(/\s/g, '') !== ''
  },

  data: _elem => {
    return {
      caption: '',
    }
  },

  form: () => [
    {
      label: formatMessage('Add a caption'),
      dataKey: 'caption',
    },
  ],

  update: (elem, data) => {
    let caption = elem.querySelector('caption')
    if (!caption) {
      caption = elem.ownerDocument.createElement('caption')
      prepend(elem, caption)
    }
    caption.textContent = data.caption
    return elem
  },

  message: () =>
    formatMessage('Tables should include a caption describing the contents of the table.'),

  why: () =>
    formatMessage(
      'Screen readers cannot interpret tables without the proper structure. Table captions describe the context and general understanding of the table.'
    ),

  link: 'https://www.w3.org/TR/WCAG20-TECHS/H39.html',
  linkText: () => formatMessage('Learn more about using captions with tables'),
}
