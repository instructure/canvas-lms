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
import type {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'

interface ModuleItem {
  lid: string | number
  title: string
}

const getModuleItemId = (assignment: TeacherAssignmentType): string | number | undefined => {
  // If the MODULE_ITEM_ID is present, then use that
  if (ENV.MODULE_ITEM_ID) {
    return ENV.MODULE_ITEM_ID
  }

  // If there is exactly one module item associated with the assignment, use that
  const moduleItems = assignment?.moduleItems as ModuleItem[] | undefined
  if (moduleItems && moduleItems.length === 1) {
    return moduleItems[0].lid
  }
  return undefined
}

export default getModuleItemId
