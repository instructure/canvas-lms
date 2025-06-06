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
import {useScope as createI18nScope} from '@canvas/i18n'

// import {TeacherAssignmentShape} from '../assignmentData'
import AssignmentDescription from './AssignmentDescription'
import Overrides from './Overrides/Overrides'
import AddHorizontalRuleButton from './AddHorizontalRuleButton'

import {View} from '@instructure/ui-view'

const I18n = createI18nScope('asignments_2')

interface DetailsProps {
  assignment: any // TeacherAssignmentShape type
  onChangeAssignment: (field: string, value: any) => void
  onValidate: (...args: any[]) => void
  invalidMessage: (...args: any[]) => any
  readOnly?: boolean
}

export default function Details({
  assignment,
  onChangeAssignment,
  onValidate,
  invalidMessage,
  readOnly = false,
}: DetailsProps) {
  // html is sanitized on the server side
  return (
    <View as="div" margin="0">
      <AssignmentDescription
        text={assignment.description}
        onChange={handleDescriptionChange}
        readOnly={readOnly}
      />
      <Overrides
        assignment={assignment}
        onChangeAssignment={onChangeAssignment}
        onValidate={onValidate}
        invalidMessage={invalidMessage}
        readOnly={readOnly}
      />
      {readOnly ? null : (
        <AddHorizontalRuleButton onClick={addOverride} label={I18n.t('Add Override')} />
      )}
    </View>
  )

  function handleDescriptionChange(desc: string) {
    onChangeAssignment('description', desc)
  }
}

// TODO: the real deal
function addOverride() {}
