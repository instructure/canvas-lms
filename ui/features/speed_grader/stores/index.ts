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

import {create} from 'zustand'
import {subscribeWithSelector} from 'zustand/middleware'
import type {RubricAssessmentSelect} from '@canvas/rubrics/react/types/rubric'
import type {RubricAssessmentUnderscore} from '@canvas/rubrics/react/utils'

type SpeedGraderStore = {
  currentStudentId: string
  currentStudentName?: string
  currentStudentAvatarPath?: string
  gradesLoading: Record<string, boolean>
  rubricAssessmentTrayOpen: boolean
  rubricAssessors: RubricAssessmentSelect
  rubricHidePoints: boolean
  studentAssessment?: RubricAssessmentUnderscore
  selfAssessment?: RubricAssessmentUnderscore | null
  rubricSavedComments?: Record<string, string[]>
  student_entries?: object
}

const useStore = create(
  subscribeWithSelector<SpeedGraderStore>(() => ({
    currentStudentId: '',
    currentStudentName: '',
    currentStudentAvatarPath: '',
    gradesLoading: {},
    rubricAssessmentTrayOpen: false,
    rubricAssessors: [],
    rubricHidePoints: false,
    studentAssessment: undefined,
    rubricSavedComments: {},
    student_entries: {},
  })),
)

export const updateState = (newState: Partial<SpeedGraderStore>) => {
  useStore.setState(state => {
    return {...state, newState}
  })
}
export default useStore
