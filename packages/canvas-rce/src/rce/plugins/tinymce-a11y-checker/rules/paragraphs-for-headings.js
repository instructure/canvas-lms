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
import {changeTag} from '../utils/dom'

const MAX_HEADING_LENGTH = 120
const IS_HEADING = {
  H1: true,
  H2: true,
  H3: true,
  H4: true,
  H5: true,
  H6: true,
}

export default {
  'max-heading-length': MAX_HEADING_LENGTH,

  id: 'paragraphs-for-headings',
  test: elem => {
    if (!IS_HEADING[elem.tagName]) {
      return true
    }
    return elem.textContent.length <= MAX_HEADING_LENGTH
  },

  data: _elem => {
    return {
      change: false,
    }
  },

  form: () => [
    {
      label: formatMessage('Change heading tag to paragraph'),
      checkbox: true,
      dataKey: 'change',
    },
  ],

  update: (elem, data) => {
    let ret = elem
    if (data.change) {
      ret = changeTag(elem, 'p')
    }
    return ret
  },

  message: () => formatMessage('Headings should not contain more than 120 characters.'),

  why: () =>
    formatMessage(
      'Sighted users browse web pages quickly, looking for large or bolded headings. Screen reader users rely on headers for contextual understanding. Headers should be concise within the proper structure.'
    ),

  link: '',
}
