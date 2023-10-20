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

import config from '../config'
import Dispatcher from '../dispatcher'
import K from '../constants'
import pollProgress from '../services/poll_progress'
import populateCollection from './util/populate_collection'
import QuizReports from '../backbone/collections/quiz_reports'
import Store from '@canvas/quiz-legacy-client-apps/store'

const quizReports = new QuizReports()

const triggerDownload = function (url) {
  const iframe = document.createElement('iframe')
  iframe.style.display = 'none'
  iframe.src = url
  document.body.appendChild(iframe)
}

let generationRequests = []

export default new Store(
  'quizReports',
  {
    /**
     * Load quiz reports from the Canvas API.
     *
     * @async
     * @fires change
     * @needs_cfg quizReportsUrl
     * @needs_cfg includesAllVersions
     *
     * @return {Promise}
     *         Fulfills when the reports have been loaded.
     */
    load() {
      const onLoad = this.populate.bind(this)
      const url = config.quizReportsUrl

      if (!url) {
        return Promise.reject(new Error('Missing configuration parameter "quizReportsUrl".'))
      }

      return quizReports
        .fetch({
          data: {
            include: ['progress', 'file'],
            includes_all_versions: config.includesAllVersions,
          },
        })
        .then(function (payload) {
          onLoad(payload, {replace: true, track: true})
        })
    },

    /**
     * Populate the store with pre-loaded data.
     *
     * @param {Object} payload
     *        The payload to extract the reports from. This is what you received
     *        by hitting the Canvas reports index JSON-API endpoint.
     *
     * @param {Object} [options={}]
     * @param {Boolean} [options.replace=true]
     *        Forwarded to Stores.Common#populateCollection
     *
     * @param {Boolean} [options.track=false]
     *        Pass to true if the payload may contain any reports that are
     *        currently being generated, then the store will track their
     *        generation progress.
     *
     * @fires change
     */
    populate(payload, options) {
      options = options || {}

      populateCollection(quizReports, payload, options.replace)

      if (options.track) {
        quizReports.where({isGenerating: true}).forEach(report => {
          this.trackReportGeneration(report, false)
        })
      }

      this.emitChange()
    },

    getAll() {
      return quizReports.toJSON()
    },

    actions: {
      generate(reportType, resolve, reject) {
        const quizReport = quizReports.findWhere({reportType})

        if (quizReport) {
          if (quizReport.get('isGenerating')) {
            return reject(new Error('report is already being generated'))
          } else if (quizReport.get('isGenerated')) {
            return reject(new Error('report is already generated'))
          }
        }

        quizReports.generate(reportType).then(quizReport => {
          this.trackReportGeneration(quizReport, true)
          resolve()
        }, reject)
      },

      regenerate(reportId, resolve, reject) {
        const quizReport = quizReports.get(reportId)
        const progress = quizReport.get('progress')

        if (!quizReport) {
          return reject(new Error('no such report'))
        } else if (!progress) {
          return reject(new Error('report is not being generated'))
        } else if (progress.workflowState !== K.PROGRESS_FAILED) {
          return reject(new Error('report generation is not stuck'))
        }

        quizReports.generate(quizReport.get('reportType')).then(quizReport => {
          this.stopTracking(quizReport.get('id'))
          this.trackReportGeneration(quizReport, true)

          resolve()
        }, reject)
      },

      abort(reportId, resolve, reject) {
        const quizReport = quizReports.get(reportId)

        if (!quizReport) {
          return reject(new Error('no such quiz report'))
        } else if (!quizReport.get('progress')) {
          return reject(new Error('quiz report is not being generated'))
        }

        quizReport.destroy({wait: true}).then(() => {
          this.stopTracking(quizReport.get('id'))

          // destroy() would remove the report from the collection but we
          // don't want that... just reload the report from the server:
          quizReports.add(quizReport)
          quizReport.fetch().then(resolve, reject)
        }, reject)
      },
    },

    __reset__() {
      quizReports.reset()
      generationRequests = []

      return Store.prototype.__reset__.call(this)
    },

    /** @private */
    trackReportGeneration(quizReport, autoDownload) {
      const quizReportId = quizReport.get('id')
      let generationRequest = generationRequests.filter(function (request) {
        return request.quizReportId === quizReportId
      })[0]

      // we're already tracking
      if (generationRequest) {
        return
      }

      generationRequest = {
        quizReportId,
        autoDownload,
      }

      generationRequests.push(generationRequest)

      const emitChange = this.emitChange.bind(this)
      const progressUrl = quizReport.get('progress').url

      const poll = function () {
        return pollProgress(progressUrl, {
          interval: 1000,
          onTick(completion, progress) {
            quizReport.set('progress', progress)
            emitChange()
          },
        })
      }

      const reload = function () {
        return quizReport.fetch({
          data: {
            include: ['progress', 'file'],
          },
        })
      }

      poll()
        .then(reload, reload)
        .finally(() => {
          this.stopTracking(quizReportId)

          if (generationRequest.autoDownload && quizReport.get('isGenerated')) {
            triggerDownload(quizReport.get('file').url)
          }

          emitChange()
        })
    },

    /** @private */
    stopTracking(quizReportId) {
      const request = generationRequests.filter(function (request) {
        return request.quizReportId === quizReportId
      })[0]

      if (request) {
        generationRequests.splice(generationRequests.indexOf(request), 1)
      }
    },
  },
  Dispatcher
)
