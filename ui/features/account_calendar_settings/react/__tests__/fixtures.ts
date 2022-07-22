/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export const RESPONSE_ACCOUNT_1 = [
  {
    id: '1',
    name: 'University',
    parent_account_id: null,
    root_account_id: '0',
    visible: true,
    sub_account_count: 24
  },
  {
    id: '11',
    name: 'Big Account',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 15
  },
  {
    id: '4',
    name: 'CPMS',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 2
  },
  {
    id: '6',
    name: 'Elementary',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 1
  },
  {
    id: '3',
    name: 'Manually-Created Courses',
    parent_account_id: '1',
    root_account_id: '1',
    visible: false,
    sub_account_count: 0
  }
]

export const RESPONSE_ACCOUNT_3 = [
  {
    id: '3',
    name: 'Manually-Created Courses',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 0
  }
]

export const RESPONSE_ACCOUNT_4 = [
  {
    id: '4',
    name: 'CPMS',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 1
  },
  {
    id: '5',
    name: 'CS',
    parent_account_id: '4',
    root_account_id: '1',
    visible: true,
    sub_account_count: 1
  }
]

export const COLLECTION_ACCOUNT_1 = {
  '1': {
    id: 1,
    name: 'University (24)',
    collections: [11, 4, 6],
    children: [
      {
        calendarVisible: true,
        id: 1,
        name: 'University'
      },
      {
        calendarVisible: false,
        id: 3,
        name: 'Manually-Created Courses'
      }
    ]
  },
  '4': {
    id: 4,
    name: 'CPMS (2)',
    collections: [],
    children: [
      {
        calendarVisible: true,
        id: 4,
        name: 'CPMS'
      }
    ]
  },
  '6': {
    id: 6,
    name: 'Elementary (1)',
    collections: [],
    children: [{calendarVisible: true, id: 6, name: 'Elementary'}]
  },
  '11': {
    id: 11,
    name: 'Big Account (15)',
    collections: [],
    children: [{calendarVisible: true, id: 11, name: 'Big Account'}]
  }
}

export const COLLECTION_ACCOUNT_1_4 = {
  '1': {
    id: 1,
    name: 'University (24)',
    collections: [11, 4, 6],
    children: [
      {
        calendarVisible: true,
        id: 1,
        name: 'University'
      },
      {
        calendarVisible: false,
        id: 3,
        name: 'Manually-Created Courses'
      }
    ]
  },
  '4': {
    id: 4,
    name: 'CPMS (2)',
    collections: [5],
    children: [
      {
        calendarVisible: true,
        id: 4,
        name: 'CPMS'
      }
    ]
  },
  '5': {
    id: 5,
    name: 'CS (1)',
    collections: [],
    children: [{calendarVisible: true, id: 5, name: 'CS'}]
  },
  '6': {
    id: 6,
    name: 'Elementary (1)',
    collections: [],
    children: [{calendarVisible: true, id: 6, name: 'Elementary'}]
  },
  '11': {
    id: 11,
    name: 'Big Account (15)',
    collections: [],
    children: [{calendarVisible: true, id: 11, name: 'Big Account'}]
  }
}

export const COLLECTION_ACCOUNT_3 = {
  '3': {
    id: 3,
    name: 'Manually-Created Courses (0)',
    collections: [],
    children: [{calendarVisible: true, id: 3, name: 'Manually-Created Courses'}]
  }
}
