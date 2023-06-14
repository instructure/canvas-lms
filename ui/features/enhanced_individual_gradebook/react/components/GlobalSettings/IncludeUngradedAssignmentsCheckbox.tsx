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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {GradebookSettings} from '../../../../gradebook/react/default_gradebook/gradebook.d'
import userSettings from '@canvas/user-settings'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  saveViewUngradedAsZeroToServer?: boolean | null
  settings?: GradebookSettings | null
  contextId?: string | null
}
export default function IncludeUngradedAssignmentsCheckbox({
  saveViewUngradedAsZeroToServer,
  settings,
  contextId,
}: Props) {
  const [viewUngraded, setViewUngraded] = useState(
    saveViewUngradedAsZeroToServer && settings
      ? settings.view_ungraded_as_zero === 'true'
      : userSettings.contextGet('include_ungraded_assignments') || false
  )

  const handleViewUngradedChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked
    setViewUngraded(checked)
    userSettings.contextSet('include_ungraded_assignments', checked)
    if (!saveViewUngradedAsZeroToServer) {
      return
    }
    doFetchApi({
      method: 'PUT',
      path: `/api/v1/courses/${contextId}/gradebook_settings`,
      body: {
        gradebook_settings: {
          view_ungraded_as_zero: checked ? 'true' : 'false',
        },
      },
    })
  }

  return (
    <div
      className="checkbox"
      style={{padding: 12, margin: '10px 0px', background: '#eee', borderRadius: 5}}
    >
      <label className="checkbox" htmlFor="ungraded_checkbox">
        <input
          type="checkbox"
          id="ungraded_checkbox"
          name="ungraded_checkbox"
          checked={viewUngraded}
          onChange={handleViewUngradedChange}
        />
        {I18n.t('View Ungraded as 0')}
      </label>
    </div>
  )
}
