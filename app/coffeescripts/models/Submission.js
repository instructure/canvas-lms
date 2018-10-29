//
// Copyright (C) 2011 - present Instructure, Inc.
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
//

import Backbone from 'Backbone'

export default class Submission extends Backbone.Model {
  constructor(...args) {
    super(...args)
    this.isGraded = this.isGraded.bind(this)
    this.hasSubmission = this.hasSubmission.bind(this)
    this.withoutGradedSubmission = this.withoutGradedSubmission.bind(this)
    this.present = this.present.bind(this)
  }

  isGraded() {
    return this.get('grade') != null
  }

  hasSubmission() {
    return !!this.get('submission_type')
  }

  withoutGradedSubmission() {
    return !this.hasSubmission() && !this.isGraded()
  }

  present() {
    const json = this.toJSON()
    json.submitted_or_graded = !this.withoutGradedSubmission()
    return json
  }
}
