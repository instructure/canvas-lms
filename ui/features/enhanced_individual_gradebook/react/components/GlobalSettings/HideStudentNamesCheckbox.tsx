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
import userSettings from '@canvas/user-settings'

const I18n = useI18nScope('enhanced_individual_gradebook')

export default function HideStudentNamesCheckbox() {
  const [hideStudentNames, setHideStudentNames] = useState(
    userSettings.contextGet('hide_student_names') || false
  )

  const handleHideStudentNamesChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked
    userSettings.contextSet('hide_student_names', checked)
    setHideStudentNames(checked)
  }

  return (
    <div
      className="checkbox"
      style={{padding: 12, margin: '10px 0px', background: '#eee', borderRadius: 5}}
    >
      <label className="checkbox" htmlFor="hide_names_checkbox">
        <input
          type="checkbox"
          id="hide_names_checkbox"
          name="hide_names_checkbox"
          checked={hideStudentNames}
          onChange={handleHideStudentNamesChange}
        />
        {I18n.t('Hide Student Names')}
      </label>
    </div>
  )
}
