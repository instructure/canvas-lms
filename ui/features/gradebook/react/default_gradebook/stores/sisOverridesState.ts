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
import type {GradebookStore} from './index'
import type {AssignmentGroup} from '../../../../../api.d'

export type SisOverrideState = {
  areSisOverridesLoaded: boolean
  sisOverrides: AssignmentGroup[]
  fetchSisOverrides: () => Promise<void>
}

export default (
  set: SetState<GradebookStore>,
  get: GetState<GradebookStore>
): SisOverrideState => ({
  sisOverrides: [],

  areSisOverridesLoaded: false,

  fetchSisOverrides: (): Promise<void> => {
    const url = `/api/v1/courses/${get().courseId}/assignment_groups`
    const params = {
      exclude_assignment_submission_types: ['wiki_page'],
      exclude_response_fields: [
        'description',
        'in_closed_grading_period',
        'needs_grading_count',
        'rubric',
      ],
      include: ['assignments', 'grades_published', 'overrides'],
      override_assignment_dates: false,
    }

    return get()
      .dispatch.getDepaginated<AssignmentGroup[]>(url, params)
      .then(sisOverrides => {
        set({
          areSisOverridesLoaded: true,
          sisOverrides,
        })
      })
  },
})
