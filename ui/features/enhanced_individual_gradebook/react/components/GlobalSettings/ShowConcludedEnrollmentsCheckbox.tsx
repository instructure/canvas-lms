/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {HandleCheckboxChange} from '../../../types'
import CheckboxTemplate from './CheckboxTemplate'

const I18n = useI18nScope('enhanced_individual_gradebook')
type Props = {
  settingsUpdateUrl?: string | null
  handleCheckboxChange: HandleCheckboxChange
  showConcludedEnrollments: boolean
}

export default function ShowConcludedEnrollmentsCheckbox({
  settingsUpdateUrl,
  handleCheckboxChange,
  showConcludedEnrollments,
}: Props) {
  const handleShowConcludedEnrollmentsChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked
    doFetchApi({
      method: 'PUT',
      path: settingsUpdateUrl,
      body: {
        gradebook_settings: {
          show_concluded_enrollments: checked ? 'true' : 'false',
        },
      },
    })
    handleCheckboxChange('showConcludedEnrollments', checked)
  }

  return (
    <CheckboxTemplate
      label={I18n.t('Show Concluded Enrollments')}
      checked={showConcludedEnrollments}
      onChange={handleShowConcludedEnrollmentsChange}
      dataTestId="show-concluded-enrollments-checkbox"
    />
  )
}
