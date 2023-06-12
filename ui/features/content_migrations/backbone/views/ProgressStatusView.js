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
/* eslint-disable object-shorthand */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import template from '../../jst/ProgressStatus.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('content_migrations')

extend(ProgressingStatusView, Backbone.View)

function ProgressingStatusView() {
  return ProgressingStatusView.__super__.constructor.apply(this, arguments)
}

ProgressingStatusView.prototype.template = template

ProgressingStatusView.prototype.initialize = function () {
  ProgressingStatusView.__super__.initialize.apply(this, arguments)
  this.progress = this.model.progressModel
  this.model.on('change:workflow_state', this.render)
  return this.progress.on('change:workflow_state', this.render)
}

ProgressingStatusView.prototype.render = function () {
  let ref, ref1, statusView
  if (
    (statusView =
      (ref = this.model.collection) != null
        ? (ref1 = ref.view) != null
          ? ref1.getStatusView(this.model)
          : void 0
        : void 0)
  ) {
    return this.$el.html(statusView)
  } else {
    return ProgressingStatusView.__super__.render.apply(this, arguments)
  }
}

ProgressingStatusView.prototype.toJSON = function () {
  const json = ProgressingStatusView.__super__.toJSON.apply(this, arguments)
  json.statusLabel = this.statusLabel()
  json.status = this.status({
    humanize: true,
  })
  return json
}

ProgressingStatusView.prototype.statusLabelClassMap = {
  completed: 'label-success',
  completed_with_issues: 'label-warning',
  failed: 'label-important',
  running: 'label-info',
}

// Status label css class is determined depending on the status a current item is in.
// Status labels are mapped to the statusLabel hash. This string should be a css class.
//
// @returns statusLabel (type: string)
// @api private
ProgressingStatusView.prototype.statusLabel = function () {
  return this.statusLabelClassMap[this.statusLabelKey()]
}

// Returns the key for the status label map.
//
// @returns key (for statusLabelClassMap)
// @api private
ProgressingStatusView.prototype.statusLabelKey = function () {
  const count = this.model.get('migration_issues_count')
  if (this.status() === 'completed' && count) {
    return 'completed_with_issues'
  } else {
    return this.status()
  }
}

// Status of the current migration or migration progress. Checks the migration
// first. If the migration is completed or failed we don't need to check
// the status of the actual migration progress model since it most likely
// wasn't pulled anyway and doesn't have a workflow_state that makes sense.
// Only if the migration's workflow state isn't failed or completed do we
// use the migration progress models workflow state.
//
// Options can be
//   humanize: true (returns the status humanized)
//
//   ie:
//     workflow_state = 'waiting_for_select'
//     @status(humanize: true) # => "Waiting for select"
//
// @expects options (type: object)
// @returns status (type: string)
// @api private
ProgressingStatusView.prototype.statusLabelMap = {
  queued: function () {
    return I18n.t('Queued')
  },
  running: function () {
    return I18n.t('Running')
  },
  completed: function () {
    return I18n.t('Completed')
  },
  failed: function () {
    return I18n.t('Failed')
  },
  waiting_for_select: function () {
    return I18n.t('Waiting for Selection')
  },
  pre_processing: function () {
    return I18n.t('Pre-processing')
  },
}

ProgressingStatusView.prototype.status = function (options) {
  if (options == null) {
    options = {}
  }
  const humanize = options.humanize
  const migrationState = this.model.get('workflow_state')
  const progressState = this.progress.get('workflow_state')
  let status = migrationState !== 'running' ? migrationState : progressState || 'queued'
  if (humanize) {
    const translation = this.statusLabelMap[status]
    if (translation) {
      status = translation()
    } else {
      status = status.charAt(0).toUpperCase() + status.substring(1).toLowerCase()
      status = status.replace(/_/g, ' ')
    }
  }
  return status
}

export default ProgressingStatusView
