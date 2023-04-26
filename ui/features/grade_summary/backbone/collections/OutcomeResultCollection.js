//
// Copyright (C) 2015 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import WrappedCollection from './WrappedCollection'

class OutcomeResultCollection extends WrappedCollection {
  constructor(...args) {
    super(...args)
    this.handleReset = this.handleReset.bind(this)
    this.handleAdd = this.handleAdd.bind(this)
  }

  url = () =>
    `/api/v1/courses/${this.course_id}/outcome_results?user_ids[]=${this.user_id}&outcome_ids[]=${this.outcome.id}&include[]=alignments&per_page=100`

  comparator = model => -1 * model.get('submitted_or_assessed_at').getTime()

  initialize() {
    super.initialize(...arguments)
    this.model = Outcome.extend({
      defaults: {
        points_possible: this.outcome.get('points_possible'),
        mastery_points: this.outcome.get('mastery_points'),
      },
    })
    this.course_id = ENV.context_asset_string?.replace('course_', '')
    this.user_id = ENV.student_id
    this.on('reset', this.handleReset)
    this.on('add', this.handleAdd)
  }

  handleReset = () => this.each(this.handleAdd)

  handleAdd(model) {
    const alignment_id = model.get('links').alignment
    model.set('alignment_name', this.alignments.get(alignment_id)?.get('name'))
    if (model.get('points_possible') > 0) {
      model.set('score', model.get('points_possible') * model.get('percent'))
    } else {
      model.set('score', model.get('mastery_points') * model.get('percent'))
    }
  }

  parse(response) {
    if (this.alignments === null || typeof this.alignments === 'undefined') {
      this.alignments = new Backbone.Collection([])
    }
    this.alignments.add(response?.linked?.alignments || [])
    return response[this.key]
  }
}

OutcomeResultCollection.prototype.key = 'outcome_results'
OutcomeResultCollection.prototype.model = Outcome
OutcomeResultCollection.optionProperty('outcome')
OutcomeResultCollection.prototype.loadAll = true

export default OutcomeResultCollection
