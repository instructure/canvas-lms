/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var RSVP = require('rsvp')
  var $ = require('jquery')
  var CoreAdapter = require('canvas_quizzes/core/adapter')
  var K = require('../constants')
  var config = require('../config')
  var Adapter = new CoreAdapter(config)
  var pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize')

  var fetchProgress = function(url) {
    return Adapter.request({
      type: 'GET',
      url: url
    }).then(function(payload) {
      return pickAndNormalize(payload, K.PROGRESS_ATTRS)
    })
  }

  return function pollProgress(url, options) {
    var poll, poller
    var service = RSVP.defer()

    options = options || {}

    $(window).on('beforeunload.progress', function() {
      return clearTimeout(poller)
    })

    poll = function() {
      fetchProgress(url).then(
        function(data) {
          if (options.onTick) {
            options.onTick(data.completion, data)
          }

          if (data.workflowState === K.PROGRESS_FAILED) {
            service.reject()
          } else if (data.workflowState === K.PROGRESS_COMPLETE) {
            service.resolve()
          } else {
            poller = setTimeout(poll, options.interval || config.pollingFrequency)
          }
        },
        function() {
          service.reject()
        }
      )
    }

    poll()

    return service.promise
  }
})
