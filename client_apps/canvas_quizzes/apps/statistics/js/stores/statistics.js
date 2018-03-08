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
  var Store = require('canvas_quizzes/core/store')
  var Dispatcher = require('../core/dispatcher')
  var config = require('../config')
  var QuizStats = require('../collections/quiz_statistics')
  var populateCollection = require('./common/populate_collection')
  var quizStats = new QuizStats([])

  /**
   * @class Statistics.Stores.Statistics
   * Load stats.
   */
  var store = new Store(
    'statistics',
    {
      getInitialState: function() {
        return {
          loading: false,
          stats_can_load: true
        }
      },

      /**
       * Load quiz statistics.
       *
       * @needs_cfg quizStatisticsUrl
       * @async
       * @fires change
       *
       * @return {RSVP.Promise}
       *         Fulfills when the stats have been loaded and injected.
       */
      load: function() {
        if (!config.quizStatisticsUrl) {
          return config.onError('Missing configuration parameter "quizStatisticsUrl".')
        }

        this.setState({loading: true})

        return quizStats
          .fetch({
            success: this.checkForStatsNoLoad.bind(this)
          })
          .then(
            function onLoad(payload) {
              this.populate(payload)
              this.setState({loading: false})
            }.bind(this)
          )
      },

      checkForStatsNoLoad: function(collection, response) {
        if (response == null) {
          this.setState({stats_can_load: false})
        }
      },

      /**
       * Populate the store with pre-loaded statistics data you've received from
       * the Canvas stats index endpoint (JSON-API or JSON).
       *
       * @fires change
       */
      populate: function(payload) {
        populateCollection(quizStats, payload)
        this.emitChange()
      },

      get: function() {
        var props

        if (quizStats.length) {
          props = quizStats.first().toJSON()
          // props.expandingAll = this.isExpandingAll();
        }

        return props
      },

      isLoading: function() {
        return this.state.loading
      },

      canBeLoaded: function() {
        return this.state.stats_can_load
      },

      getSubmissionStatistics: function() {
        var stats = this.get()
        if (stats) {
          return stats.submissionStatistics
        }
      },

      getQuestionStatistics: function() {
        var stats = this.get()

        if (stats) {
          return stats.questionStatistics
        }
      },

      filterForSection: function(sectionId) {
        if (sectionId == 'all') {
          quizStats.url = config.quizStatisticsUrl
        } else {
          quizStats.url = config.quizStatisticsUrl + '?section_ids=' + sectionId
        }

        config.section_ids = sectionId
        this.setState({loading: true})

        return quizStats
          .fetch({
            success: this.checkForStatsNoLoad.bind(this)
          })
          .then(
            function onLoad(payload) {
              this.populate(payload)
              this.setState({loading: false})
            }.bind(this)
          )
      },

      __reset__: function() {
        quizStats.reset()
        return Store.prototype.__reset__.call(this)
      }
    },
    Dispatcher
  )

  return store
})
