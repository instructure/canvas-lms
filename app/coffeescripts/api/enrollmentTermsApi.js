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

import _ from 'underscore'
import Depaginate from 'jsx/shared/CheatDepaginator'

const listUrl = () => ENV.ENROLLMENT_TERMS_URL

const deserializeTerms = termGroups =>
  _.flatten(
    _.map(termGroups, group =>
      _.map(group.enrollment_terms, term => {
        const groupID = term.grading_period_group_id
        const newGroupID = _.isNumber(groupID) ? groupID.toString() : groupID
        return {
          id: term.id.toString(),
          name: term.name,
          startAt: term.start_at ? new Date(term.start_at) : null,
          endAt: term.end_at ? new Date(term.end_at) : null,
          createdAt: term.created_at ? new Date(term.created_at) : null,
          gradingPeriodGroupId: newGroupID
        }
      })
    )
  )

export default {
  list(terms) {
    return new Promise((resolve, reject) => {
      Depaginate(listUrl())
        .then(response => resolve(deserializeTerms(response)))
        .fail(error => reject(error))
    })
  }
}
