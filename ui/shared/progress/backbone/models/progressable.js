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

/* eslint-disable object-shorthand */

import Progress from './Progress'

// # Mixin to models that work with the Progress API.
// #
// # When you call `save` on your model, and the server returns
// # a `progress_url` attribute, this mixin will set up a progress model
// # and start polling
// #
// # The progress model is availabel via @progressModel.
// #
// # @event progressResolved - fires when the progress is complete

export default {
  initialize: function () {
    this.progressModel = new Progress()
    return this.attachProgressable()
  },
  // Returns the progressModel.pollDfd instead of the @save deferred
  saveWithProgressDeferred: function () {
    this.save()
    return this.progressModel.pollDfd
  },
  attachProgressable: function () {
    this.on(
      'change:progress_url',
      (function (_this) {
        return function (model, url) {
          return _this.progressModel.set({
            url: url,
            workflow_state: 'queued',
          })
        }
      })(this)
    )
    return this.progressModel.on(
      'complete',
      (function (_this) {
        return function () {
          return _this.fetch({
            success: function () {
              return _this.trigger('progressResolved')
            },
          })
        }
      })(this)
    )
  },
}
