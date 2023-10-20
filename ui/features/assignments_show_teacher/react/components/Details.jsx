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

import React from 'react'
import {bool, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {TeacherAssignmentShape} from '../assignmentData'
import AssignmentDescription from './AssignmentDescription'
import Overrides from './Overrides/Overrides'
import AddHorizontalRuleButton from './AddHorizontalRuleButton'

import {View} from '@instructure/ui-view'

const I18n = useI18nScope('asignments_2')

Details.propTypes = {
  assignment: TeacherAssignmentShape.isRequired,
  onChangeAssignment: func.isRequired,
  onValidate: func.isRequired,
  invalidMessage: func.isRequired,
  readOnly: bool,
}
Details.defaultProps = {
  readOnly: false,
}

export default function Details(props) {
  // html is sanitized on the server side
  return (
    <View as="div" margin="0">
      <AssignmentDescription
        text={props.assignment.description}
        onChange={handleDescriptionChange}
        readOnly={props.readOnly}
      />
      <Overrides
        assignment={props.assignment}
        onChangeAssignment={props.onChangeAssignment}
        onValidate={props.onValidate}
        invalidMessage={props.invalidMessage}
        readOnly={props.readOnly}
      />
      {props.readOnly ? null : (
        <AddHorizontalRuleButton onClick={addOverride} label={I18n.t('Add Override')} />
      )}
    </View>
  )

  function handleDescriptionChange(desc) {
    props.onChangeAssignment('description', desc)
  }
}

// TODO: the real deal
function addOverride() {}
