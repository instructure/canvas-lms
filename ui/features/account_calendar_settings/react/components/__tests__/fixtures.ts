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
    id: 1,
    name: 'University',
    parent_account_id: null,
    root_account_id: '0',
    visible: true,
    sub_account_count: 4,
  },
  {
    id: 11,
    name: 'Big Account',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 15,
  },
  {
    id: 4,
    name: 'CPMS',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 1,
  },
  {
    id: 6,
    name: 'Elementary',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 1,
  },
  {
    id: 3,
    name: 'Manually-Created Courses',
    parent_account_id: '1',
    root_account_id: '1',
    visible: false,
    sub_account_count: 0,
  },
]

export const RESPONSE_ACCOUNT_3 = [
  {
    id: 3,
    name: 'Manually-Created Courses',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 0,
  },
]

export const RESPONSE_ACCOUNT_4 = [
  {
    id: 4,
    name: 'CPMS',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 1,
  },
  {
    id: 5,
    name: 'CS',
    parent_account_id: '4',
    root_account_id: '1',
    visible: true,
    sub_account_count: 0,
  },
]

export const RESPONSE_ACCOUNT_5 = [
  {
    id: 1,
    name: 'Manually-Created Courses',
    parent_account_id: null,
    root_account_id: '1',
    visible: true,
    sub_account_count: 1,
    auto_subscribe: true,
  },
  {
    id: 8,
    name: 'Another sub-account',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 0,
    auto_subscribe: false,
  },
]

export const RESPONSE_ACCOUNT_6 = [
  {
    id: 3,
    name: 'Manually-Created Courses',
    parent_account_id: '1',
    root_account_id: '1',
    visible: true,
    sub_account_count: 1,
    auto_subscribe: false,
  },
]
