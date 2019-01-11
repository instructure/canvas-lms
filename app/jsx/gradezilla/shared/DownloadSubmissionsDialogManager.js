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

import INST from 'INST'
import $ from 'jquery'
import 'jquery.instructure_misc_helpers'

class DownloadSubmissionsDialogManager {
  constructor(assignment, downloadUrlTemplate, submissionsDownloading) {
    this.assignment = assignment
    this.downloadUrl = $.replaceTags(downloadUrlTemplate, 'assignment_id', assignment.id)
    this.showDialog = this.showDialog.bind(this)
    this.validSubmissionTypes = ['online_upload', 'online_text_entry', 'online_url']
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
    INST.downloadSubmissions(this.downloadUrl, cb)
  }
}

export default DownloadSubmissionsDialogManager
