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
      avatar_url: 'http://avatar_url',
    },
    created_at: '2019-07-04T12:00:00Z',
    updated_at: '2019-07-24T12:00:00Z',
    read_state: 'read',
    content_export: {
      id: '3',
      workflow_state: 'exported',
      created_at: '2019-07-04T12:00:00Z',
      attachment: {
        id: '4',
        created_at: '2019-07-04T12:00:00Z',
        url: 'https://attachment.url',
      },
    },
    ...overrides,
  }
}

export const assignmentShare = mockShare()

export const senderlessAssignmentShare = mockShare({sender: null})

export const attachmentShare = mockShare({
  content_type: 'attachment',
  id: '3',
  name: 'attachment.pdf',
})

export const readDiscussionShare = mockShare({
  id: '2',
  name: 'A Course Discussion',
  read_state: 'read',
  content_type: 'discussion_topic',
  created_at: '2019-07-05T12:00:00Z',
  updated_at: '2019-07-25T12:00:00Z',
})
export const unreadDiscussionShare = {...readDiscussionShare, read_state: 'unread'}
