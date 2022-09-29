/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import EventStore from './stores/events'
import config from './config'

let update

/**
 * @class Events.Core.Controller
 * @private
 *
 * The controller is responsible for keeping the UI up-to-date with the
 * data layer.
 */
const Controller = {
  getState: () => ({
    useHashRouter: config.useHashRouter,
    submission: EventStore.getSubmission(),
    questions: EventStore.getQuestions(),
    events: EventStore.getAll(),
    isLoading: EventStore.isLoading(),
    attempt: EventStore.getAttempt(),
    availableAttempts: EventStore.getAvailableAttempts(),
  }),

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
  start(onUpdate) {
    update = () => {
      onUpdate(Controller.getState())
    }

    EventStore.addChangeListener(update)

    if (config.loadOnStartup) {
      return Controller.load()
    } else {
      return Promise.resolve()
    }
  },

  /**
   * Load initial application data; quiz statistics and reports.
   */
  load() {
    return EventStore.loadInitialData().then(EventStore.load.bind(EventStore))
  },

  /**
   * Stop listening to data changes.
   */
  stop() {
    if (update) {
      EventStore.removeChangeListener(update)
      update = null
    }
  },
}

export default Controller
