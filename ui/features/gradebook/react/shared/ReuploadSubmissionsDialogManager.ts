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

import authenticity_token from '@canvas/authenticity-token'
import re_upload_submissions_form from '@canvas/grading/jst/re_upload_submissions_form.handlebars'
import {setupSubmitHandler} from '@canvas/assignments/jquery/reuploadSubmissionsHelper'
import $ from 'jquery'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import type {Assignment} from '../../../../api.d'

class ReuploadSubmissionsDialogManager {
  reuploadUrl: string

  userAssetString: string

  assignment: Assignment

  downloadedSubmissionsMap: {
    [assignmentId: string]: boolean
  }

  constructor(
    assignment: Assignment,
    reuploadUrlTemplate,
    userAssetString: string,
    downloadedSubmissionsMap
  ) {
    this.assignment = assignment
    this.downloadedSubmissionsMap = downloadedSubmissionsMap
    this.reuploadUrl = $.replaceTags(reuploadUrlTemplate, 'assignment_id', assignment.id)
    this.showDialog = this.showDialog.bind(this)
    this.userAssetString = userAssetString
  }

  isDialogEnabled() {
    return this.downloadedSubmissionsMap[this.assignment.id]
  }

  getReuploadForm(cb) {
    if (ReuploadSubmissionsDialogManager.reuploadForm) {
      return ReuploadSubmissionsDialogManager.reuploadForm
    }

    ReuploadSubmissionsDialogManager.reuploadForm = $(
      re_upload_submissions_form({authenticityToken: authenticity_token()})
    ).dialog({
      width: 400,
      modal: true,
      resizable: false,
      autoOpen: false,
      close: () => {
        if (typeof cb === 'function') {
          cb()
        }
      },
    })

    setupSubmitHandler(this.userAssetString)

    return ReuploadSubmissionsDialogManager.reuploadForm
  }

  showDialog(cb) {
    const form = this.getReuploadForm(cb)
    form.attr('action', this.reuploadUrl).dialog('open')
  }
}

export default ReuploadSubmissionsDialogManager
