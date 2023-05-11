// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

const I18n = useI18nScope('gradebookSharedGradebookexportManager')

type Export = {
  progressId: string
  attachmentId: string
  filename: string
}

type StartExportResponse = {
  attachmentUrl: string
  updatedAt: Date
}

class GradebookExportManager {
  private _exportCancelled: boolean

  export?: Export

  pollingInterval: number

  exportingUrl: string

  monitoringBaseUrl: string

  attachmentBaseUrl: string

  cancelBaseUrl: string

  currentUserId: string

  exportStatusPoll: number | null = null

  updateExportState?: (name?: string, val?: number) => void

  static DEFAULT_POLLING_INTERVAL = 2000

  static DEFAULT_MONITORING_BASE_URL = '/api/v1/progress'

  static DEFAULT_ATTACHMENT_BASE_URL = '/api/v1/users'

  static DEFAULT_CANCEL_BASE_URL = '/api/v1/progress'

  static exportCompleted(workflowState) {
    return workflowState === 'completed'
  }

  // Returns false if the workflowState is 'failed' or an unknown state
  static exportFailed(workflowState) {
    if (workflowState === 'failed') return true

    return !['completed', 'queued', 'running'].includes(workflowState)
  }

  constructor(
    exportingUrl,
    currentUserId,
    existingExport,
    pollingInterval = GradebookExportManager.DEFAULT_POLLING_INTERVAL,
    updateExportState?: (name?: string, val?: number) => void
  ) {
    this.pollingInterval = pollingInterval

    this.exportingUrl = exportingUrl
    this.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL
    this.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`
    this.cancelBaseUrl = GradebookExportManager.DEFAULT_CANCEL_BASE_URL
    this.currentUserId = currentUserId
    this.updateExportState = updateExportState
    this._exportCancelled = false

    if (existingExport) {
      const workflowState = existingExport.workflowState

      if (workflowState !== 'completed' && workflowState !== 'failed') {
        this.export = existingExport
      }
    }
  }

  monitoringUrl() {
    if (!(this.export && this.export.progressId)) return undefined

    return `${this.monitoringBaseUrl}/${this.export.progressId}`
  }

  attachmentUrl() {
    if (!(this.attachmentBaseUrl && this.export && this.export.attachmentId)) return undefined

    return `${this.attachmentBaseUrl}/${this.export.attachmentId}`
  }

  cancelUrl() {
    if (!this.export?.progressId) return ''

    return `${this.cancelBaseUrl}/${this.export.progressId}/cancel`
  }

  clearMonitor() {
    if (this.exportStatusPoll) {
      window.clearInterval(this.exportStatusPoll)
      this.exportStatusPoll = null
    }
  }

  setExportState(completion?: number, filename?: string) {
    this.updateExportState?.(filename ?? this.export?.filename, completion)
  }

  async cancelExport() {
    this._exportCancelled = true
    this.setExportState(undefined)

    await axios.post(this.cancelUrl())
  }

  clearMonitorExport() {
    this.clearMonitor()
    this.setExportState(undefined)
    this.export = undefined
  }

  monitorExport(resolve, reject) {
    if (!this.monitoringUrl()) {
      this.export = undefined

      reject(I18n.t('No way to monitor gradebook exports provided!'))
    }

    this.exportStatusPoll = window.setInterval(() => {
      if (this._exportCancelled) {
        this.clearMonitorExport()
        resolve()
      }

      axios
        .get(this.monitoringUrl() || '')
        .then(response => {
          if (this._exportCancelled) {
            this.clearMonitorExport()
            resolve()
          }

          const {workflow_state: workflowState, completion} = response.data

          this.setExportState(completion)
          if (GradebookExportManager.exportCompleted(workflowState)) {
            this.clearMonitor()

            // Export is complete => let's get the attachment url
            axios
              .get(this.attachmentUrl() || '')
              .then(attachmentResponse => {
                const resolution: StartExportResponse = {
                  attachmentUrl: attachmentResponse.data.url,
                  updatedAt: attachmentResponse.data.updated_at,
                }

                this.export = undefined
                resolve(resolution)
              })
              .catch(reject)
          } else if (GradebookExportManager.exportFailed(workflowState)) {
            this.clearMonitor()

            reject(I18n.t('Error exporting gradebook: %{msg}', {msg: response.data.message}))
          }
        })
        .catch(reject)
    }, this.pollingInterval)
  }

  startExport(
    gradingPeriodId: string | null,
    getAssignmentOrder,
    showStudentFirstLastName = false,
    getStudentOrder,
    currentView = false
  ) {
    if (!this.exportingUrl) {
      return Promise.reject(I18n.t('No way to export gradebooks provided!'))
    }

    if (this.export) {
      // We already have an ongoing export, ignoring this call to start a new one
      return Promise.reject(I18n.t('An export is already in progress.'))
    }

    this._exportCancelled = false

    const params = {
      grading_period_id: gradingPeriodId,
      show_student_first_last_name: showStudentFirstLastName,
      current_view: currentView,
      assignment_order: undefined,
      student_order: undefined,
    }

    const assignmentOrder = getAssignmentOrder()
    if (assignmentOrder && assignmentOrder.length > 0) {
      params.assignment_order = assignmentOrder
    }

    const studentOrder = getStudentOrder()
    if (studentOrder && studentOrder.length > 0) {
      params.student_order = studentOrder
    }

    return axios.post(this.exportingUrl, params).then(response => {
      const {progress_id: progressId, attachment_id: attachmentId, filename} = response.data
      this.export = {
        progressId,
        attachmentId,
        filename,
      }

      this.setExportState(0, filename)

      return new Promise<{
        attachmentUrl: string
        updatedAt: string
      }>(this.monitorExport.bind(this))
    })
  }
}

export default GradebookExportManager
