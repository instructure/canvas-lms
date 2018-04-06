/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {bool, func} from 'prop-types'
import React from 'react'
import I18n from 'i18n!assignments'

export default function ModeratedGradingCheckbox(props) {
  function handleChange() {
    props.onChange(!props.checked)
  }

  return (
    <label className="ModeratedGrading__CheckboxLabel" htmlFor="assignment_moderated_grading">
      <input type="hidden" name="moderated_grading" value={props.checked} />
      <input
        className="ModeratedGrading__Checkbox"
        checked={props.checked}
        id="assignment_moderated_grading"
        name="moderated_grading"
        onChange={handleChange}
        type="checkbox"
      />
      <strong className="ModeratedGrading__CheckboxLabelText">{I18n.t('Moderated Grading')}</strong>
      <div className="ModeratedGrading__CheckboxDescription">
        {I18n.t('Allow moderator to review multiple independent grades for selected submissions')}
      </div>
    </label>
  )
}

ModeratedGradingCheckbox.propTypes = {
  checked: bool.isRequired,
  onChange: func.isRequired
}
