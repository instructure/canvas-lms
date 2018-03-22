/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {string, shape, arrayOf, bool} from 'prop-types'
import createStore from './createStore'

const TermsStore = createStore({
  getUrl() {
    return `/api/v1/accounts/${this.context.rootAccountId}/terms`
  },

  jsonKey: 'enrollment_terms'
})

export const propType = shape({
  data: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired,
      end_at: string,
      start_at: string
    })
  ),
  loading: bool
}).isRequired

export default TermsStore
