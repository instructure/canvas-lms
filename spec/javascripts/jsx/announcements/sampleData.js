/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

const data = {
  announcements: [{
    id: '1',
    position: 2,
    published: true,
    title: 'hello world',
    message: 'lorem ipsum foo bar baz',
    posted_at: (new Date).toString(),
    author: {
      id: '1',
      display_name: 'John Doe',
      html_url: 'http://example.org/user/5',
    },
    read_state: 'read',
    unread_count: 0,
    discussion_subentry_count: 0,
    locked: false,
    user_count: 2,
    html_url: 'http://example.org/announcement/5',
    permissions: {
      delete: true
    }
  }],
}

export default data
