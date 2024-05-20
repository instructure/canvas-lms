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

import type {GetState, SetState} from 'zustand'
import {getFinalGradeOverrides} from '@canvas/grading/FinalGradeOverrideApi'
import type {GradebookStore} from './index'
import type {FinalGradeOverrideMap} from '@canvas/grading/grading.d'
import type GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'

type StudentInfo = {
  id: string
  avatarUrl: string
  name: string
  gradesUrl: string
  enrollmentId: string
}
export type FinalGradeOverrideState = {
  allowFinalGradeOverride: boolean
  areFinalGradeOverridesLoaded: boolean
  finalGradeOverrides: FinalGradeOverrideMap
  finalGradeOverrideTrayProps: {
    gradeEntry?: GradeOverrideEntry
    isOpen: boolean
    isFirstStudent: boolean
    isLastStudent: boolean
    studentInfo?: StudentInfo
  }
  fetchFinalGradeOverrides: () => Promise<void>
  toggleFinalGradeOverrideTray: (isOpen?: boolean) => void
}

export default (
  set: SetState<GradebookStore>,
  get: GetState<GradebookStore>
): FinalGradeOverrideState => ({
  allowFinalGradeOverride: false,

  finalGradeOverrides: {},

  areFinalGradeOverridesLoaded: false,

  fetchFinalGradeOverrides: (): Promise<void> => {
    return getFinalGradeOverrides(get().courseId).then(data => {
      if (data?.finalGradeOverrides) {
        set({
          finalGradeOverrides: data?.finalGradeOverrides,
          areFinalGradeOverridesLoaded: true,
        })
      }
    })
  },

  finalGradeOverrideTrayProps: {
    isOpen: false,
    isFirstStudent: false,
    isLastStudent: false,
  },

  toggleFinalGradeOverrideTray: (isOpen?: boolean): void => {
    const existingProps = get().finalGradeOverrideTrayProps
    set({
      finalGradeOverrideTrayProps: {
        ...existingProps,
        isOpen: isOpen ?? !existingProps.isOpen,
      },
    })
  },
})
