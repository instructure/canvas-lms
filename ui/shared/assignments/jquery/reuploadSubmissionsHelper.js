/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.instructure_forms' // brings in $.fn.formSubmit

const I18n = useI18nScope('assignment!reupload_submissions_helper')

const formId = 're_upload_submissions_form'

function beforeSubmit({submissions_zip: submissionsZip}) {
  if (!submissionsZip) {
    return false
  } else if (!submissionsZip.match(/\.zip$/)) {
    $(this).formErrors({submissions_zip: I18n.t('Please upload files as a .zip')})
    return false
  }

  const submitButton = this.find('button[type="submit"]')
  submitButton.prop('disabled', true)
  submitButton.text(I18n.t('Uploading...'))

  return true
}

function success(attachment) {
  const $form = $(`#${formId}`)
  // We've already posted the file data to files#create_pending and have an
  // attachment that points to the file. That means we no longer need the
  // submissions_zip input, and we need to add an input with the attachment ID.
  $form.find('input[name="submissions_zip"]').remove()
  $form.removeAttr('enctype')
  // xsslint safeString.property id
  $form.append(`<input type="hidden" name="attachment_id" value="${attachment.id}">`)
  // Now that we've generated an attachment and included its ID in the form, submit the form
  // "normally" (don't trigger jQuery submit) to POST to gradebooks#submissions_zip_upload.
  document.getElementById(formId).submit()
}

function error(_data) {
  const submitButton = this.find('button[type="submit"]')
  submitButton.prop('disabled', false)
  submitButton.text(I18n.t('Upload Files'))
  return this
}

function errorFormatter(_error) {
  return {errorMessage: I18n.t('Upload error. Please try again.')}
}

export function setupSubmitHandler(userAssetString) {
  const options = {
    fileUpload: true,
    fileUploadOptions: {
      context_code: userAssetString,
      formDataTarget: 'uploadDataUrl',
      intent: 'submissions_zip_upload',
      preparedFileUpload: true,
      singleFile: true,
      upload_only: true,
      preferFileValueForInputName: false,
    },
    object_name: 'attachment',
    beforeSubmit,
    error,
    errorFormatter,
    success,
  }

  $(`#${formId}`).formSubmit(options)

  return options
}
