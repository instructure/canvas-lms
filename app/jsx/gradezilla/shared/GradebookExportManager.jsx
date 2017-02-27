define([
  'axios',
  'i18n!gradebook'
], (
  axios, I18n
) => {
  class GradebookExportManager {
    static DEFAULT_POLLING_INTERVAL = 2000;
    static DEFAULT_MONITORING_BASE_URL = '/api/v1/progress';
    static DEFAULT_ATTACHMENT_BASE_URL = '/api/v1/users';

    static exportCompleted (workflowState) {
      return workflowState === 'completed';
    }

    // Returns false if the workflowState is 'failed' or an unknown state
    static exportFailed (workflowState) {
      if (workflowState === 'failed') return true;

      return !['completed', 'queued', 'running'].includes(workflowState);
    }

    constructor (exportingUrl, currentUserId, existingExport, pollingInterval = GradebookExportManager.DEFAULT_POLLING_INTERVAL) {
      this.pollingInterval = pollingInterval;

      this.exportingUrl = exportingUrl;
      this.monitoringBaseUrl = GradebookExportManager.DEFAULT_MONITORING_BASE_URL;
      this.attachmentBaseUrl = `${GradebookExportManager.DEFAULT_ATTACHMENT_BASE_URL}/${currentUserId}/files`;
      this.currentUserId = currentUserId;

      if (existingExport) {
        const workflowState = existingExport.workflowState;

        if (workflowState !== 'completed' && workflowState !== 'failed') {
          this.export = existingExport;
        }
      }
    }

    monitoringUrl () {
      if (!(this.export && this.export.progressId)) return undefined;

      return `${this.monitoringBaseUrl}/${this.export.progressId}`;
    }

    attachmentUrl () {
      if (!(this.attachmentBaseUrl && this.export && this.export.attachmentId)) return undefined;

      return `${this.attachmentBaseUrl}/${this.export.attachmentId}`;
    }

    clearMonitor () {
      if (this.exportStatusPoll) {
        window.clearInterval(this.exportStatusPoll);
        this.exportStatusPoll = null;
      }
    }

    monitorExport (resolve, reject) {
      if (!this.monitoringUrl()) {
        this.export = undefined;

        reject(I18n.t('No way to monitor gradebook exports provided!'));
      }

      this.exportStatusPoll = window.setInterval(() => {
        axios.get(this.monitoringUrl()).then((response) => {
          const workflowState = response.data.workflow_state;

          if (GradebookExportManager.exportCompleted(workflowState)) {
            this.clearMonitor();

            // Export is complete => let's get the attachment url
            axios.get(this.attachmentUrl()).then((attachmentResponse) => {
              const resolution = {
                attachmentUrl: attachmentResponse.data.url,
                updatedAt: attachmentResponse.data.updated_at
              };

              this.export = undefined;

              resolve(resolution);
            }).catch((error) => {
              reject(error);
            });
          } else if (GradebookExportManager.exportFailed(workflowState)) {
            this.clearMonitor();

            reject(I18n.t('Error exporting gradebook: %{msg}', { msg: response.data.message }));
          }
        });
      }, this.pollingInterval);
    }

    startExport (gradingPeriodId) {
      if (!this.exportingUrl) {
        return Promise.reject(I18n.t('No way to export gradebooks provided!'));
      }

      if (this.export) {
        // We already have an ongoing export, ignoring this call to start a new one
        return Promise.reject(I18n.t('An export is already in progress.'));
      }

      const params = {
        grading_period_id: gradingPeriodId
      };

      return axios.get(this.exportingUrl, { params }).then((response) => {
        this.export = {
          progressId: response.data.progress_id,
          attachmentId: response.data.attachment_id
        };

        return new Promise(this.monitorExport.bind(this));
      });
    }
  }

  return GradebookExportManager;
});

