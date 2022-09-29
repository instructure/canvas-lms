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

import config from './config'
import quizReports from './stores/reports'
import quizStatistics from './stores/statistics'

let update

/**
 * @class Statistics.Core.Controller
 * @private
 *
 * The controller is responsible for keeping the UI up-to-date with the
 * data layer.
 */
const Controller = {
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
      onUpdate({
        quizStatistics: quizStatistics.get(),
        isLoadingStatistics: quizStatistics.isLoading(),
        canBeLoaded: quizStatistics.canBeLoaded(),
        quizReports: quizReports.getAll(),
      })
    }

    quizStatistics.addChangeListener(update)
    quizReports.addChangeListener(update)

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
    if (config.quizStatisticsUrl) {
      return Promise.all([quizStatistics.load(), quizReports.load()])
    } else {
      return Promise.reject(
        new Error(`
          You have requested to load on start-up, but have not
          provided a url to load from in CQS.config.quizStatisticsUrl.
        `)
      )
    }
  },

  /**
   * Stop listening to data changes.
   */
  stop() {
    if (update) {
      quizStatistics.removeChangeListener(update)
      quizReports.removeChangeListener(update)

      update = null
    }
  },
}

export default Controller
