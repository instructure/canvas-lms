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

import {SimpleSelect} from '@instructure/ui-simple-select'

const I18n = useI18nScope('discussion_create')

type Props = {
  assignmentGroup: string
  setAssignmentGroup: (id: string | undefined) => void
  availableAssignmentGroups: any[]
}

export const AssignmentGroupSelect = ({
  assignmentGroup,
  setAssignmentGroup,
  availableAssignmentGroups,
}: Props) => {
  return (
    <SimpleSelect
      data-testid="assignment-group-input"
      renderLabel={I18n.t('Assignment Group')}
      value={assignmentGroup}
      onChange={(_event, {id}) => {
        setAssignmentGroup(id)
      }}
    >
      {availableAssignmentGroups.map(group => (
        <SimpleSelect.Option id={group._id} key={group._id} value={group._id}>
          {group.name}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}
