/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import * as apiClient from '../apiClient'
import axios from '@canvas/axios'

describe('apiClient', () => {
  describe('addExternalFeed', () => {
    it('provides arguments to the post request correctly', () => {
      axios.post = jest.fn()
      apiClient.addExternalFeed(
        {
          contextType: 'course',
          contextId: 1,
        },
        {
          url: 'reddit.com',
          verbosity: 'full',
          header_match: 'this # should work',
        }
      )
      expect(axios.post).toHaveBeenCalledWith('/api/v1/courses/1/external_feeds', {
        url: 'reddit.com',
        verbosity: 'full',
        header_match: 'this # should work',
      })
    })
  })
})
