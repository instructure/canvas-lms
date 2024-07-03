/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

const INITIAL_STATE = {
  courseParams: {
    courseId: 1,
    roles: [{id: 1}, {id: 2}, {id: 3}],
    sections: [{id: 1}, {id: 2}, {id: 3}],
    inviteUsersURL: '/courses/#/invite_users',
  },
  inputParams: {
    searchType: 'unique_id',
    nameList: 'foo, bar, baz',
    role: '1',
    section: '1',
    limitPrivilege: false,
    canReadSIS: true,
  },
  apiState: {
    pendingCount: 0,
    error: undefined,
  },
  userValidationResult: {
    validUsers: [],
    duplicates: {},
    missing: {},
  },
  usersToBeEnrolled: [],
  usersEnrolled: false,
}

export default INITIAL_STATE
