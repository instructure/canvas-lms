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

import $ from 'jquery'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import type {Assignment} from '../../../../api.d'

class DownloadSubmissionsDialogManager {
  assignment: Assignment

  downloadUrl: string

  validSubmissionTypes = ['online_upload', 'online_text_entry', 'online_url']

  submissionsDownloading: (assignmentId: string) => void

  constructor(
    assignment: Assignment,
    downloadUrlTemplate,
    submissionsDownloading: (assignmentId: string) => void
  ) {
    this.assignment = assignment
    this.downloadUrl = $.replaceTags(downloadUrlTemplate, 'assignment_id', assignment.id)
    this.showDialog = this.showDialog.bind(this)
    this.submissionsDownloading = submissionsDownloading
  }

  isDialogEnabled() {
    return (
      this.assignment.submission_types &&
      this.assignment.submission_types.some(t => this.validSubmissionTypes.includes(t)) &&
      this.assignment.has_submitted_submissions
    )
  }

  showDialog(cb) {
    this.submissionsDownloading(this.assignment.id)

    // @ts-expect-error
    INST.downloadSubmissions(this.downloadUrl, cb)
  }
}

export default DownloadSubmissionsDialogManager
