// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {ProgressCamelized} from '../default_gradebook/gradebook.d'

import GradebookApi from '../default_gradebook/apis/GradebookApi'

const I18n = useI18nScope('gradebookSharedScoreToUngradedManager')

class ScoreToUngradedManager {
  static DEFAULT_POLLING_INTERVAL = 2000

  static DEFAULT_MONITORING_BASE_URL = '/api/v1/progress'

  static processCompleted(workflowState: string) {
    return workflowState === 'completed'
  }

  // Returns false if the workflowState is 'failed' or an unknown state
  static processFailed(workflowState: string) {
    if (workflowState === 'failed') return true
    return !['completed', 'queued', 'running'].includes(workflowState)
  }

  pollingInterval: number

  monitoringBaseUrl: string

  process?: ProgressCamelized

  processStatusPoll?: number

  constructor(
    existingProcess?: ProgressCamelized,
    pollingInterval: number = ScoreToUngradedManager.DEFAULT_POLLING_INTERVAL
  ) {
    this.pollingInterval = pollingInterval
    this.monitoringBaseUrl = ScoreToUngradedManager.DEFAULT_MONITORING_BASE_URL

    if (existingProcess) {
      const workflowState = existingProcess.workflowState
      if (!['completed', 'failed'].includes(workflowState || '')) {
        this.process = existingProcess
      }
    }
  }

  monitoringUrl() {
    if (!(this.process && this.process.progressId)) return undefined
    return `${this.monitoringBaseUrl}/${this.process.progressId}`
  }

  clearMonitor() {
    if (this.processStatusPoll) {
      window.clearInterval(this.processStatusPoll)
      this.processStatusPoll = undefined
      this.process = undefined
    }
  }

  monitorProcess(resolve, reject) {
    if (!this.monitoringUrl()) {
      this.process = undefined
      reject(I18n.t('No way to monitor score to ungraded provided!'))
    }

    this.processStatusPoll = window.setInterval(() => {
      return axios.get(this.monitoringUrl()!).then(response => {
        const workflowState = response.data.workflow_state

        if (ScoreToUngradedManager.processCompleted(workflowState)) {
          this.clearMonitor()
          resolve({})
        } else if (ScoreToUngradedManager.processFailed(workflowState)) {
          this.clearMonitor()
          reject(I18n.t('%{msg}', {msg: response.data.message}))
        }
      })
    }, this.pollingInterval)
  }

  startProcess(courseId?: string, options: any = {}) {
    if (this.process) {
      return Promise.reject(I18n.t('A process is already in progress.'))
    }

    return GradebookApi.applyScoreToUngradedSubmissions(courseId, options)
      .then(response => {
        this.process = {
          progressId: response.data.id,
          workflowState: response.data.workflow_state,
        }

        return new Promise(this.monitorProcess.bind(this))
      })
      .catch(reason => {
        throw I18n.t('Score to ungraded process failed: %{reason}', {reason})
      })
  }
}

export default ScoreToUngradedManager
