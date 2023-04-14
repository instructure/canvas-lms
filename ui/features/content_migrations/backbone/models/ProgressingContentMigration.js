/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import ProgressModel from '@canvas/content-migrations/backbone/models/ContentMigrationProgress'
import IssuesCollection from '../collections/ContentMigrationIssueCollection'

extend(ProgressingContentMigration, Backbone.Model)

// Summary
//   Represents a model that is progressing through its
//   workflow_state steps.

function ProgressingContentMigration() {
  return ProgressingContentMigration.__super__.constructor.apply(this, arguments)
}

ProgressingContentMigration.prototype.initialize = function (attr, options) {
  let ref
  ProgressingContentMigration.__super__.initialize.apply(this, arguments)
  this.course_id =
    ((ref = this.collection) != null ? ref.course_id : void 0) ||
    (options != null ? options.course_id : void 0) ||
    this.get('course_id')
  this.buildChildren()
  this.pollIfRunning()
  return this.syncProgressUrl()
}

// Create child associations for this model. Each
// ProgressingMigration should have a ProgressModel
// and an IssueCollection
//
// Creates:
//   @progressModel
//   @issuesCollection
//
// @api private

ProgressingContentMigration.prototype.buildChildren = function () {
  this.progressModel = new ProgressModel({
    url: this.get('progress_url'),
    course_id: this.course_id,
  })
  return (this.issuesCollection = new IssuesCollection(null, {
    course_id: this.course_id,
    content_migration_id: this.get('id'),
  }))
}

// Logic to determin if we need to start polling progress. Progress
// shouldn't need to be polled unless this migration is in a running
// state.
//
// @api private

ProgressingContentMigration.prototype.pollIfRunning = function () {
  if (this.get('workflow_state') === 'running' || this.get('workflow_state') === 'pre_processing') {
    return this.progressModel.poll()
  }
}

// Sometimes the progress url for this progressing migration might change or
// be added after initialization. If this happens, the @progressModel's url needs
// to be updated to reflect the change.
//
// @api private

ProgressingContentMigration.prototype.syncProgressUrl = function () {
  return this.on(
    'change:progress_url',
    (function (_this) {
      return function () {
        return _this.progressModel.set('url', _this.get('progress_url'))
      }
    })(this)
  )
}

export default ProgressingContentMigration
