/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import * as actions from './actions'
import {getScoringRangeSplitWarning} from './score-helpers'

// reset aria alert 500ms after being set so that subsequent alerts
// can be triggered with the same text
export const clearAriaAlert = (state, dispatch) => {
  if (state.get('aria_alert')) {
    setTimeout(() => dispatch(actions.clearAriaAlert()), 1000)
  }
}

// clear warning about too many assignment sets in a scoring
// range when that condition has been resolved
export const clearScoringRangeWarning = (state, dispatch) => {
  const message = getScoringRangeSplitWarning()
  if (state.get('global_warning') === message) {
    let needsWarning = false
    state.getIn(['rule', 'scoring_ranges']).forEach(sr => {
      if (sr.get('assignment_sets').size > 2) {
        needsWarning = true
      }
    })
    if (!needsWarning) {
      dispatch(actions.clearGlobalWarning())
    }
  }
}

const actors = [clearAriaAlert, clearScoringRangeWarning]

let acting = false

export default function initActors(store) {
  store.subscribe(() => {
    // Ensure that any action dispatched by actors do not result in a new
    // actor run, allowing actors to dispatch with impunity
    if (!acting) {
      acting = true
      actors.forEach(actor => {
        actor(store.getState(), store.dispatch)
      })
      acting = false
    }
  })
}
