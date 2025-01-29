/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {StoreApi} from 'zustand'
import type {GradebookStore} from './index'

type ImportAssignment = {
  id: string
  name: string
  courseId: string
}
export type RubricAssessmentImportState = {
  rubricAssessmentImportTrayProps: {
    isOpen: boolean
    assignment?: ImportAssignment
  }
  toggleRubricAssessmentImportTray: (isOpen?: boolean, assignment?: ImportAssignment) => void
}

export default (
  set: StoreApi<GradebookStore>['setState'],
  get: StoreApi<GradebookStore>['getState'],
): RubricAssessmentImportState => ({
  rubricAssessmentImportTrayProps: {
    isOpen: false,
    assignment: undefined,
  },

  toggleRubricAssessmentImportTray: (isOpen?: boolean, assignment?: ImportAssignment): void => {
    const existingProps = get().rubricAssessmentImportTrayProps
    set({
      rubricAssessmentImportTrayProps: {
        ...existingProps,
        isOpen: isOpen ?? !existingProps.isOpen,
        assignment,
      },
    })
  },
})
