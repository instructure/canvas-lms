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
import $ from 'jquery'
import BaseUploader from './BaseUploader'

export default class ZipUploader extends BaseUploader {
  constructor(fileOptions, folder, contextId, contextType) {
    super(fileOptions, folder)

    this.onPreflightComplete = this.onPreflightComplete.bind(this)
    this.onUploadPosted = this.onUploadPosted.bind(this)
    this.getContentMigration = this.getContentMigration.bind(this)
    this.pullMigrationProgress = this.pullMigrationProgress.bind(this)
    this.trackProgress = this.trackProgress.bind(this)

    this.contextId = contextId
    this.contextType = contextType
    this.migrationProgress = 0
  }

  createPreFlightParams() {
    let params
    return (params = {
      migration_type: 'zip_file_importer',
      settings: {
        folder_id: this.folder.id
      },
      pre_attachment: {
        name: this.options.name || this.file.name,
        size: this.file.size,
        content_type: this.file.type,
        on_duplicate: this.options.dup || 'rename',
        no_redirect: true
      }
    })
  }

  getPreflightUrl() {
    return `/api/v1/${this.contextType}/${this.contextId}/content_migrations`
  }

  onPreflightComplete(data) {
    this.uploadData = data.pre_attachment
    this.contentMigrationId = data.id
    return this._actualUpload()
  }

  onUploadPosted() {
    return this.getContentMigration()
  }

  // get the content migration when ready and use progress api to pull migration progress
  getContentMigration() {
    return $.getJSON(
      `/api/v1/${this.contextType}/${this.contextId}/content_migrations/${this.contentMigrationId}`
    ).then(results => {
      if (!results.progress_url) {
        return setTimeout(() => this.getContentMigration(), 500)
      } else {
        return this.pullMigrationProgress(results.progress_url)
      }
    })
  }

  pullMigrationProgress(url) {
    return $.getJSON(url).then(results => {
      this.trackMigrationProgress(results.completion || 0)
      if (results.workflow_state === 'failed') {
        return this.deferred.reject()
      } else if (results.completion < 100) {
        setTimeout(() => {
          this.pullMigrationProgress(url)
        }, 1000)
      } else {
        return this.onMigrationComplete()
      }
    })
  }

  onMigrationComplete() {
    // reload to get new files to appear
    return this.folder.folders
      .fetch({reset: true})
      .then(() => this.folder.files.fetch({reset: true}).then(() => this.deferred.resolve()))
  }

  trackProgress(e) {
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
