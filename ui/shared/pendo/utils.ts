/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

export function getPrimaryRole(currentUserRoles: string[]): string {
  const roleScores: Record<string, number> = {
    user: 1,
    observer: 2,
    student: 3,
    designer: 4,
    ta: 5,
    teacher: 6,
    admin: 7,
    root_admin: 8,
  }

  let highestRole = 'user'

  currentUserRoles.forEach(role => {
    if (roleScores[role] !== undefined) {
      if (roleScores[role] > roleScores[highestRole]) {
        highestRole = role
      }
    }
  })

  return highestRole
}
