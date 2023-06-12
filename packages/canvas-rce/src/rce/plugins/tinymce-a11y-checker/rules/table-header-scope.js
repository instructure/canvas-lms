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

const VALID_SCOPES = ['row', 'col', 'rowgroup', 'colgroup']

export default {
  id: 'table-header-scope',
  test: elem => {
    if (elem.tagName !== 'TH') {
      return true
    }
    return VALID_SCOPES.indexOf(elem.getAttribute('scope')) !== -1
  },

  data: elem => {
    return {
      scope: elem.getAttribute('scope') || 'none',
    }
  },

  form: () => [
    {
      label: formatMessage('Set header scope'),
      dataKey: 'scope',
      options: [
        ['none', formatMessage('None')],
        ['row', formatMessage('Row')],
        ['col', formatMessage('Column')],
        ['rowgroup', formatMessage('Row group')],
        ['colgroup', formatMessage('Column group')],
      ],
    },
  ],

  update: (elem, data) => {
    if (data.header === 'none') {
      elem.removeAttribute('scope')
    } else {
      elem.setAttribute('scope', data.scope)
    }
    return elem
  },

  message: () => formatMessage('Tables headers should specify scope.'),

  why: () =>
    formatMessage(
      'Screen readers cannot interpret tables without the proper structure. Table headers provide direction and content scope.'
    ),

  link: 'https://www.w3.org/TR/WCAG20-TECHS/H63.html',
  linkText: () => formatMessage('Learn more about using scope attributes with tables'),
}
