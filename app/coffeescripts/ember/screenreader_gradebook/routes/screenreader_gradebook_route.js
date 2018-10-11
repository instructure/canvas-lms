//
// Copyright (C) 2013 - present Instructure, Inc.
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

import {Route, ArrayProxy, set} from 'ember'
import _ from 'underscore'
import ajax from 'ic-ajax'
import fetchAllPages from '../../shared/xhr/fetch_all_pages'

const ScreenreaderGradebookRoute = Route.extend({
  model() {
    const model = {
      enrollments: fetchAllPages(ENV.GRADEBOOK_OPTIONS.enrollments_url),
      assignment_groups: ArrayProxy.create({content: []}),
      submissions: ArrayProxy.create({content: []}),
      custom_columns: fetchAllPages(ENV.GRADEBOOK_OPTIONS.custom_columns_url),
      sections: fetchAllPages(ENV.GRADEBOOK_OPTIONS.sections_url)
    }

    if (!ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled) {
      model.outcomes = model.outcome_rollups = ArrayProxy.create({content: []})
    } else {
      model.outcomes = fetchAllPages(ENV.GRADEBOOK_OPTIONS.outcome_links_url, {
        process(response) {
          return response.map(x => x.outcome)
        }
      })
      model.outcome_rollups = fetchAllPages(ENV.GRADEBOOK_OPTIONS.outcome_rollups_url, {
        process(response) {
          return _.flatten(
            response.rollups.map(row =>
              row.scores.map(cell => ({
                user_id: row.links.user,
                outcome_id: cell.links.outcome,
                score: cell.score
              }))
            )
          )
        }
      })
    }

    return model
  }
})

export default ScreenreaderGradebookRoute
