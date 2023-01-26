/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import $ from 'jquery'
import qs from 'qs'
import {useScope as useI18nScope} from '@canvas/i18n'
import Helpers from './helpers'
import {uploadFile as rawUploadFile} from '@canvas/upload-file'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('actions')
/* $.flashWarning */

const Actions = {
  uploadingImage() {
    return {
      type: 'UPLOADING_IMAGE',
    }
  },

  gotCourseImage(imageUrl) {
    return {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageUrl,
      },
    }
  },

  setModalVisibility(showModal) {
    return {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal,
      },
    }
  },

  rejectedUpload(type) {
    return {
      type: 'REJECTED_UPLOAD',
      payload: {
        rejectedFiletype: type,
      },
    }
  },

  errorUploadingImage() {
    $.flashError(I18n.t('There was an error uploading the image'))
    return {
      type: 'ERROR_UPLOADING_IMAGE',
    }
  },

  removingImage() {
    return {
      type: 'REMOVING_IMAGE',
    }
  },

  removedImage() {
    return {
      type: 'REMOVED_IMAGE',
    }
  },

  errorRemovingImage() {
    $.flashError(I18n.t('There was an error removing the image'))
    return {
      type: 'ERROR_REMOVING_IMAGE',
    }
  },

  getCourseImage(courseId, settingName, ajaxLib = axios) {
    return dispatch => {
      ajaxLib
        .get(`/api/v1/courses/${courseId}/settings`)
        .then(response => {
          dispatch(this.gotCourseImage(response.data[settingName], courseId))
        })
        .catch(() => {
          $.flashError(I18n.t('There was an error retrieving the course image'))
        })
    }
  },

  setCourseImageId(imageUrl, imageId) {
    return {
      type: 'SET_COURSE_IMAGE_ID',
      payload: {
        imageUrl,
        imageId,
      },
    }
  },

  setCourseImageUrl(imageUrl) {
    return {
      type: 'SET_COURSE_IMAGE_URL',
      payload: {
        imageUrl,
      },
    }
  },

  putImageData(courseId, imageUrl, settingName, imageId = null, ajaxLib = axios) {
    const data = imageId
      ? {[`course[${settingName}_id]`]: imageId}
      : {[`course[${settingName}_url]`]: imageUrl}

    return dispatch => {
      this.ajaxPutFormData(`/api/v1/courses/${courseId}`, data, ajaxLib)
        .then(() => {
          dispatch(
            imageId ? this.setCourseImageId(imageUrl, imageId) : this.setCourseImageUrl(imageUrl)
          )
        })
        .catch(() => {
          dispatch(this.errorUploadingImage())
        })
    }
  },

  putRemoveImage(courseId, settingName) {
    return dispatch => {
      dispatch(this.removingImage())
      this.ajaxPutFormData(`/api/v1/courses/${courseId}`, {[`course[remove_${settingName}]`]: true})
        .then(() => {
          dispatch(this.removedImage())
        })
        .catch(() => {
          dispatch(this.errorRemovingImage())
        })
    }
  },

  prepareSetImage(imageUrl, imageId, settingName, courseId, ajaxLib = axios) {
    if (imageUrl) {
      return this.putImageData(courseId, imageUrl, settingName, imageId, ajaxLib)
    } else {
      // In this case the url field was blank so we could either
      // recreate it or hit the API to get it.  We hit the api
      // to be safe.
      return dispatch => {
        ajaxLib
          .get(`/api/v1/files/${imageId}`)
          .then(response => {
            dispatch(this.putImageData(courseId, response.data.url, settingName, imageId, ajaxLib))
          })
          .catch(() => {
            dispatch(this.errorUploadingImage())
          })
      }
    }
  },

  uploadFile(event, courseId, settingName, ajaxLib = axios) {
    event.preventDefault()
    return dispatch => {
      const {type, file} = Helpers.extractInfoFromEvent(event)

      if (Helpers.isValidImageType(type)) {
        dispatch(this.uploadingImage())

        const url = `/api/v1/courses/${courseId}/files`
        const data = {
          name: file.name,
          size: file.size,
          parent_folder_path: `course_${settingName}`,
          type,
          no_redirect: true,
        }
        rawUploadFile(url, data, file, ajaxLib)
          .then(attachment => {
            dispatch(
              this.prepareSetImage(attachment.url, attachment.id, settingName, courseId, ajaxLib)
            )
          })
          .catch(_response => {
            dispatch(this.errorUploadingImage())
          })
      } else {
        dispatch(this.rejectedUpload(type))
        $.flashWarning(I18n.t("'%{type}' is not a valid image type (try jpg, png, or gif)", {type}))
      }
    }
  },

  ajaxPutFormData(path, data, ajaxLib = axios) {
    return ajaxLib.put(path, qs.stringify(data))
  },
}

export default Actions
