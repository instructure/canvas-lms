/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import Pill from './Pill'

export default {
  title: 'Examples/Evaluate/Shared/Pill',
  component: Pill,
  args: {
    studentId: 1,
    text: 'Betty Ford',
    onClick: () => {},
  },
  argTypes: {
    onClick: {action: 'Clicked'},
  },
}

const Template = args => <Pill {...args} />

export const SelectedStudent = Template.bind({})
SelectedStudent.args = {
  studentId: 1,
  text: 'Betty Ford',
  onClick: () => {},
  selected: true,
}

export const UnselectedStudent = Template.bind({})
UnselectedStudent.args = {
  studentId: 1,
  text: 'Betty Ford',
  onClick: () => {},
}

export const SelectedObserver = Template.bind({})
SelectedStudent.args = {
  studentId: 1,
  osberverId: 2,
  text: 'Adam Jones',
  onClick: () => {},
  selected: true,
}

export const UnselectedObserver = Template.bind({})
UnselectedStudent.args = {
  studentId: 1,
  osberverId: 2,
  text: 'Adam Jones',
  onClick: () => {},
}
