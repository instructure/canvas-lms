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

// Zips that are to be expanded take a different upload workflow
import axios from '@canvas/axios'
import BaseUploader from './BaseUploader'

export default class ZipUploader extends BaseUploader {
  constructor(fileOptions, folder, contextId, contextType) {
    super(fileOptions, folder)

    this.contextId = contextId
    this.contextType = contextType
    this.migrationProgress = 0
    this.onUploadPosted = this.onUploadPosted.bind(this)
    this.onUploadCancelled = this.onUploadCancelled.bind(this)
  }

  createPreFlightParams() {
    return {
      migration_type: 'zip_file_importer',
      settings: {
        folder_id: this.folder.id,
      },
      pre_attachment: {
        name: this.options.name || this.file.name,
        size: this.file.size,
        content_type: this.file.type,
        on_duplicate: this.options.dup || 'rename',
        no_redirect: true,
      },
    }
  }

  getPreflightUrl() {
    return `/api/v1/${this.contextType}/${this.contextId}/content_migrations`
  }

  onPreflightComplete = ({data}) => {
    this.uploadData = data.pre_attachment
    this.contentMigrationId = data.id
    return this._actualUpload()
  }

  onUploadPosted() {
    // at this point the user can no longer cancel the upload
    this._cancelToken = null
    // will get the cancel button un-rendered
    this.onProgress(this.progress, this.file)
    const migrationPromise = this.getContentMigration()
    super.onUploadPosted()
    return migrationPromise
  }

  // get the content migration when ready and use progress api to pull migration progress
  getContentMigration = () => {
    return axios({
      url: `/api/v1/${this.contextType}/${this.contextId}/content_migrations/${this.contentMigrationId}`,
      method: 'GET',
      responseType: 'json',
    }).then(({data}) => {
      if (!data.progress_url) {
        return new Promise((resolve, reject) => {
          setTimeout(() => {
            this.getContentMigration().then(resolve).catch(reject)
          }, 500)
        })
      } else {
        return this.pullMigrationProgress(data.progress_url)
      }
    })
  }

  pullMigrationProgress = url => {
    return axios({
      url,
      method: 'GET',
      responseType: 'json',
    }).then(({data}) => {
      this.trackMigrationProgress(data.completion || 0)
      if (data.workflow_state === 'failed') {
        throw new Error('zip file migration failed')
      } else if (data.completion < 100) {
        // The progress bar defaults to 50% complete to account for the actual
        // file upload. When we start polling the progress and the job hasn't
        // been worked, the completion is 0. So without this check, the progress
        // bar would start at 50%, then render to 0%, then render to 50% once
        // the job starts getting worked.
        if (data.completion > 0) {
          const progress = {
            loaded: data.completion,
            total: 100,
          }
          this.trackProgress(progress)
        }
        return new Promise((resolve, reject) => {
          setTimeout(() => {
            // for the sake of testing, each url has to be
            // unique, so adding a hash that's not sent to canvas
            this.pullMigrationProgress(`${url}#${data.completion}`).then(resolve).catch(reject)
          }, 1000)
        })
      } else {
        return this.onMigrationComplete()
      }
    })
  }

  onMigrationComplete() {
    this.inFlight = false
    // reload to get new files to appear
    return this.folder.folders
      .fetch({reset: true})
      .then(() => this.folder.files.fetch({reset: true}))
  }

  trackProgress = e => {
    this.progress = e.loaded / e.total
    return this.onProgress(this.progress, this.file)
  }

  // migration progress is [0..100]
  trackMigrationProgress(value) {
    return (this.migrationProgress = value / 100)
  }

  // progress counts for halp, migragtion for the other
  getProgress() {
    return (this.progress + this.migrationProgress) / 2
  }

  roundProgress() {
    const value = this.getProgress() || 0
    return Math.min(Math.round(value * 100), 100)
  }

  getFileName() {
    return this.options.name || this.file.name
  }
}
