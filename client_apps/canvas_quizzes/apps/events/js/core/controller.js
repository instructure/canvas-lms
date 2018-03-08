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
  var EventStore = require('../stores/events')
  var config = require('../config')
  var update

  var onChange = function() {
    update({
      submission: EventStore.getSubmission(),
      questions: EventStore.getQuestions(),
      events: EventStore.getAll(),
      isLoading: EventStore.isLoading(),
      attempt: EventStore.getAttempt(),
      availableAttempts: EventStore.getAvailableAttempts()
    })
  }

  /**
   * @class Events.Core.Controller
   * @private
   *
   * The controller is responsible for keeping the UI up-to-date with the
   * data layer.
   */
  var Controller = {
    /**
     * Start listening to data updates.
     *
     * @param {Function} onUpdate
     *        A callback to notify when new data comes in.
     *
     * @param {Object} onUpdate.props
     *        A set of props ready for injecting into the app layout.
     *
     * @param {Object} onUpdate.props.quizStatistics
     *        Quiz statistics.
     *        See Stores.Statistics#getQuizStatistics().
     *
     * @param {Object} onUpdate.props.quizReports
     *        Quiz reports.
     *        See Stores.Statistics#getQuizReports().
     */
    start: function(onUpdate) {
      update = onUpdate
      EventStore.addChangeListener(onChange)

      if (config.loadOnStartup) {
        Controller.load()
      }
    },

    /**
     * Load initial application data; quiz statistics and reports.
     */
    load: function() {
      EventStore.loadInitialData().then(EventStore.load.bind(EventStore))
    },

    /**
     * Stop listening to data changes.
     */
    stop: function() {
      update = undefined
    }
  }

  return Controller
})
