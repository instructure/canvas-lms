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

import axios from '@canvas/axios'
import I18n from 'i18n!modules_home_page'
import $ from 'jquery'

export const publishCourse = ({courseId}) => {
  axios
    .put(`/api/v1/courses/${courseId}`, {
      course: {event: 'offer'}
    })
    .then(() => {
      window.location.reload()
    })
    .catch(e => {
      if (e.response.status === 401 && e.response.data.status === 'unverified') {
        $.flashWarning(
          I18n.t(
            'Complete registration by clicking the “finish the registration process” link sent to your email.'
          )
        )
      } else {
        $.flashError(I18n.t('An error ocurred while publishing course'))
      }
    })
}

export const getModules = ({courseId}) => {
  return axios.get(`/api/v1/courses/${courseId}/modules`)
}
