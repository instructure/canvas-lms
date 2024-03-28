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

import create from 'zustand'
import {subscribeWithSelector} from 'zustand/middleware'
import type {RubricAssessmentDataUnderscore} from '../react/RubricAssessmentTrayWrapper/utils'

type SpeedGraderStore = {
  currentStudentId: string
  gradesLoading: Record<string, boolean>
  rubricAssessmentTrayOpen: boolean
  studentAssessmentData: RubricAssessmentDataUnderscore[]
}

const useStore = create(
  subscribeWithSelector(() => ({
    currentStudentId: '',
    gradesLoading: {},
    rubricAssessmentTrayOpen: false,
    studentAssessmentData: [],
  }))
)

export const updateState = (newState: Partial<SpeedGraderStore>) => {
  useStore.setState(state => {
    return {...state, newState}
  })
}
export default useStore
