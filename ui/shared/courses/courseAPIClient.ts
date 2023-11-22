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
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'

const I18n = useI18nScope('modules_home_page')

export const publishCourse = ({
  courseId,
  onSuccess = null,
}: {
  courseId: string
  onSuccess?: null | (() => void)
}) => {
  axios
    .put(`/api/v1/courses/${courseId}`, {
      course: {event: 'offer'},
    })
    .then(() => {
      if (onSuccess) {
        onSuccess()
      } else {
        window.location.search += 'for_reload=1'
      }
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

export const getModules = ({courseId}: {courseId: string}) => {
  return axios.get(`/api/v1/courses/${courseId}/modules`)
}
