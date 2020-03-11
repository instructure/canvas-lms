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

import authenticity_token from 'compiled/behaviors/authenticity_token'
import re_upload_submissions_form from 'jst/re_upload_submissions_form'
import I18n from 'i18n!gradebook'
import $ from 'jquery'
import 'jquery.instructure_misc_helpers'

class ReuploadSubmissionsDialogManager {
  constructor(assignment, reuploadUrlTemplate) {
    this.assignment = assignment
    this.reuploadUrl = $.replaceTags(reuploadUrlTemplate, 'assignment_id', assignment.id)
    this.showDialog = this.showDialog.bind(this)
  }

  isDialogEnabled() {
    return this.assignment.hasDownloadedSubmissions
  }

  getReuploadForm(cb) {
    if (ReuploadSubmissionsDialogManager.reuploadForm) {
      return ReuploadSubmissionsDialogManager.reuploadForm
    }

    ReuploadSubmissionsDialogManager.reuploadForm = $(
      re_upload_submissions_form({authenticityToken: authenticity_token()})
    )
      .dialog({
        width: 400,
        modal: true,
        resizable: false,
        autoOpen: false,
        close: () => {
          if (typeof cb === 'function') {
            cb()
          }
        }
      })
      .submit(function() {
        const data = $(this).getFormData()
        let submitForm = true

        if (!data.submissions_zip) {
          submitForm = false
        } else if (!data.submissions_zip.match(/\.zip$/)) {
          $(this).formErrors({submissions_zip: I18n.t('Please upload files as a .zip')})
          submitForm = false
        }

        return submitForm
      })

    return ReuploadSubmissionsDialogManager.reuploadForm
  }

  showDialog(cb) {
    const form = this.getReuploadForm(cb)
    form.attr('action', this.reuploadUrl).dialog('open')
  }
}

export default ReuploadSubmissionsDialogManager
