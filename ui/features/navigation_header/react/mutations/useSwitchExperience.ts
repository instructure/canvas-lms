/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation} from '@canvas/util/globalUtils'
import {useMutation} from '@tanstack/react-query'
import {SwitchExperienceResponse} from 'api'

const I18n = createI18nScope('use_switch_experience')

export const useSwitchExperience = () => {
  const mutationResult = useMutation({
    mutationFn: () =>
      doFetchApi<SwitchExperienceResponse>({
        path: '/api/v1/career/switch_experience',
        method: 'POST',
        body: JSON.stringify({experience: 'career'}),
        headers: {
          'Content-Type': 'application/json',
        },
      }),
    onSuccess: data => {
      if (data.json?.experience) {
        assignLocation(`/${data.json.experience}`)
      } else {
        showFlashError(I18n.t('Error switching to Canvas Career'))
      }
    },
    onError: () => {
      showFlashError(I18n.t('Error switching to Canvas Career'))
    },
  })

  return mutationResult
}
