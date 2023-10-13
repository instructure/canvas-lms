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
import {AssignmentDueDate} from './AssignmentDueDate'

export default {
  title: 'Examples/Discussion Create\\Edit/Components/AssignmentDueDate',
  component: AssignmentDueDate,
  argTypes: {},
}

export function Primary(args) {
  return (
    <AssignmentDueDate
      assignedListOptions={args.assignedListOptions}
      initialAssignedInformation={args.initialAssignedInformation}
      onAssignedInfoChange={args.onAssignedInfoChange}
    />
  )
}

const DEFAULT_LIST_OPTIONS = {
  'Master Paths': [{id: 'mp_option1', label: 'Master Path Option'}],
  'Course Sections': [
    {id: 'sec_1', label: 'Section 1'},
    {id: 'sec_2', label: 'Section 2'},
  ],
  Students: [
    {id: 'u_1', label: 'Jason'},
    {id: 'u_2', label: 'Drake'},
    {id: 'u_3', label: 'Caleb'},
    {id: 'u_4', label: 'Aaron'},
    {id: 'u_5', label: 'Chawn'},
    {id: 'u_6', label: 'Omar'},
  ],
}

Primary.args = {
  assignedListOptions: DEFAULT_LIST_OPTIONS,
  initialAssignedInformation: {
    assignedList: [],
    dueDate: '',
    availableFrom: '',
    availableUntil: '',
  },
  onAssignedInfoChange: () => {},
}
