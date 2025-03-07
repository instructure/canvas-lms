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

import {User} from '../common'

export const sourceUser: User = {
  id: '2',
  name: 'John Doe',
  short_name: 'John',
  email: 'johndoe@email.com',
  integration_id: 'int_id_1',
  sis_user_id: 'sis_id_1',
  login_id: 'login_id_1',
  communication_channels: ['john.other.email.com', 'johndoe@email.com'],
  pseudonyms: ['john.doe.unique_id'],
  enrollments: ['enrollment_1'],
}

export const destinationUser: User = {
  id: '3',
  name: 'Adrian Washington',
  short_name: 'Adrian',
  email: 'adrianwashington@email.com',
  integration_id: 'int_id_2',
  sis_user_id: 'sis_id_2',
  login_id: 'login_id_2',
  communication_channels: ['adrian.other.email.com', 'adrianwashington@email.com'],
  pseudonyms: ['adrian.washington.unique_id'],
  enrollments: ['enrollment_2'],
}

export const accountSelectOptions = [{id: '1', name: 'Account 1'}]
