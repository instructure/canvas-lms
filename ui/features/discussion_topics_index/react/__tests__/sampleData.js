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

const data = {
  discussions: [
    {
      id: '1',
      position: 2,
      published: true,
      title: 'hello world',
      posted_at: new Date().toString(),
      author: {
        display_name: 'John Doe',
      },
      read_state: 'read',
      unread_count: 0,
      permissions: {
        delete: true,
      },
    },
  ],
}

export default data
