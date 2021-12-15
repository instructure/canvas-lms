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

import React, {useState} from 'react'
import FilterNav from './FilterNav'

export default {
  title: 'Examples/Evaluate/Gradebook/FilterNav',
  component: FilterNav,
  args: {
    filters: [],
    onChange: () => {},
    modules: [
      {id: '1', name: 'Module 1'},
      {id: '2', name: 'Module 2'},
      {id: '3', name: 'Module 3'}
    ],
    assignmentGroups: [
      {id: '4', name: 'Assignment Group 4'},
      {id: '5', name: 'Assignment Group 5'},
      {id: '6', name: 'Assignment Group 6'}
    ],
    sections: [
      {id: '7', name: 'Section 7'},
      {id: '8', name: 'Section 8'},
      {id: '9', name: 'Section 9'}
    ]
  }
}

const Wrapper = props => {
  const [filters, setFilters] = useState(props.filters)
  return (
    <>
      <FilterNav {...props} filters={filters} onChange={f => setFilters(f)} />
      <pre>{JSON.stringify(filters, null, 2)}</pre>
    </>
  )
}

const Template = args => <Wrapper {...args} />
export const Default = Template.bind({})
