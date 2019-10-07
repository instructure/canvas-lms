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

function resolveValidationIssues(duplicates, missings) {
  const usersToBeEnrolled = []
  const usersToBeCreated = []

  Object.keys(duplicates).forEach(addr => {
    const dupeSet = duplicates[addr]
    if (dupeSet.createNew && dupeSet.newUserInfo.email) {
      // newUserInfo.name now optional
      usersToBeCreated.push(dupeSet.newUserInfo)
    } else if (dupeSet.selectedUserId >= 0) {
      const selectedUser = dupeSet.userList.find(u => u.user_id === dupeSet.selectedUserId)
      usersToBeEnrolled.push(selectedUser)
    }
  })
  Object.keys(missings).forEach(addr => {
    const missing = missings[addr]
    if (missing.createNew && missing.newUserInfo.email) {
      // newUserInfo.name now optional
      usersToBeCreated.push(missing.newUserInfo)
    }
  })

  return {usersToBeEnrolled, usersToBeCreated}
}

export default resolveValidationIssues
