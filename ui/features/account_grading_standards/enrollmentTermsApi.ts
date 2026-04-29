//
// Copyright (C) 2016 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {map, isNumber, flatten} from 'es-toolkit/compat'
import NaiveRequestDispatch from '@canvas/network/NaiveRequestDispatch/index'

const listUrl = () => ENV.ENROLLMENT_TERMS_URL

interface RawTerm {
  id: number
  name: string
  start_at: string | null
  end_at: string | null
  created_at: string | null
  grading_period_group_id: number | string | null
}

interface RawTermGroup {
  enrollment_terms: RawTerm[]
}

export interface EnrollmentTerm {
  id: string
  name: string
  startAt: Date | null
  endAt: Date | null
  createdAt: Date | null
  gradingPeriodGroupId: string | null
}

const deserializeTerms = (termGroups: RawTermGroup[]): EnrollmentTerm[] =>
  flatten(
    map(termGroups, group =>
      map(group.enrollment_terms, term => {
        const groupID = term.grading_period_group_id
        const newGroupID = isNumber(groupID) ? groupID.toString() : groupID
        return {
          id: term.id.toString(),
          name: term.name,
          startAt: term.start_at ? new Date(term.start_at) : null,
          endAt: term.end_at ? new Date(term.end_at) : null,
          createdAt: term.created_at ? new Date(term.created_at) : null,
          gradingPeriodGroupId: newGroupID,
        }
      }),
    ),
  )

export default {
  list() {
    return new Promise<EnrollmentTerm[]>((resolve, reject) => {
      const dispatch = new NaiveRequestDispatch()

      dispatch
        // NaiveRequestDispatch is not typed and returns jQuery-style deferred chains.
        .getDepaginated(listUrl())
        .then((response: RawTermGroup[]) => resolve(deserializeTerms(response)))
        .fail((error: unknown) => reject(error))
    })
  },
}
