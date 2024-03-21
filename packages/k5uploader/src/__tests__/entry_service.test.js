/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import EntryService from '../entry_service'

describe('EntryService', () => {
  it('parses XML entry config', () => {
    const mediaXml = `
      <xml>
        <result>
          <entries>
            <entry1_>
              <id>media_id</id>
              <mediaType/>
              <type>1</type>
            </entry1_>
          </entries>
        </result>
      </xml>
    `
    const entryService = new EntryService()
    const entry = entryService.parseRequest(mediaXml)
    expect(entry.id).toEqual('media_id')
    expect(entry.type).toEqual('1')
    expect(entry.entryId).toEqual('media_id')
  })
})
