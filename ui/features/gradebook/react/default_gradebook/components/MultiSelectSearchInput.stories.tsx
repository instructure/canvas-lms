/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import MultiSelectSearchInput from './MultiSelectSearchInput'

export default {
  title: 'Examples/Evaluate/Gradebook/MultiSelectSearchInput',
  component: MultiSelectSearchInput,
  args: {
    id: '',
    disabled: false,
    onChange: () => {},
  },
}

const Template = args => <MultiSelectSearchInput {...args} />
export const Assignment = Template.bind({})
export const Student = Template.bind({})

Assignment.args = {
  options: [
    {id: '1', text: 'Spells'},
    {id: '2', text: 'Potions'},
    {id: '3', text: 'Witchcraft'},
    {id: '4', text: 'Wizardry'},
    {id: '5', text: 'Quidditch'},
  ],
  placeholder: 'Search Assignments',
  label: 'Assignment Names',
}

Student.args = {
  options: [
    {id: '1', text: 'Harry Potter'},
    {id: '2', text: 'Vincent Crabbe'},
    {id: '3', text: 'Ariana Dumbledore'},
    {id: '4', text: 'Aberforth Dumbledore'},
    {id: '5', text: 'Xenophilius Lovegood'},
  ],
  placeholder: 'Search Students',
  label: 'Student Names',
}
