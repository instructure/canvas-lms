/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export function mockShare(overrides = {}) {
  return {
    id: '1',
    name: 'A Course Assignment',
    content_type: 'assignment',
    sender: {
      id: '2',
      display_name: 'sender name',
      avatar_url: 'http://avatar_url'
    },
    created_at: '2019-07-04T12:00:00Z',
    updated_at: '2019-07-24T12:00:00Z',
    read_state: 'read',
    ...overrides
  }
}

export const assignmentShare = mockShare()
export const discussionShare = mockShare({
  id: 2,
  name: 'A Course Discussion',
  content_type: 'discussion',
  created_at: '2019-07-05T12:00:00Z',
  updated_at: '2019-07-25T12:00:00Z'
})
