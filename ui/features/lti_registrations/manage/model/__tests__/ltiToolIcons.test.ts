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

import {ZDeveloperKeyId} from '../developer_key/DeveloperKeyId'
import {ltiToolDefaultIconUrl} from '../ltiToolIcons'

describe('ltiToolIcons', () => {
  describe('ltiToolDefaultIconUrl', () => {
    it('should return a url with an encoded tool name', () => {
      const url = ltiToolDefaultIconUrl({toolName: 'tool name', base: ''})
      expect(url).toEqual('/lti/tool_default_icon?name=tool%20name')
    })

    it('should return a url with a developer key id', () => {
      const url = ltiToolDefaultIconUrl({
        toolName: 'tool name',
        developerKeyId: ZDeveloperKeyId.parse('123'),
        base: '',
      })
      expect(url).toEqual('/lti/tool_default_icon?name=tool%20name&developer_key_id=123')
    })
  })
})
