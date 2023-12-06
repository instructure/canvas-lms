// @vitest-environment jsdom
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
import {render} from '@testing-library/react'
import {mockOverride} from '../../../test-utils'
import OverrideAssignTo from '../OverrideAssignTo'

const assignToSection = {
  set: {
    __typename: 'Section',
    lid: '17',
    sectionName: 'Section 8',
  },
}
const assignToGroup = {
  set: {
    __typename: 'Group',
    lid: '68',
    groupName: 'Yo La Tengo',
  },
}
const assignToGroupWithNoName = {
  set: {
    __typename: 'Group',
    lid: '68',
    groupName: null,
  },
}
const assignToStudents = {
  set: {
    __typename: 'AdhocStudents',
    students: [
      {lid: '2', studentName: 'Dweezil Zappa'},
      {lid: '3', studentName: 'Moon Zappa'},
    ],
  },
}

it('renders an empty OverrideAssignTo summary', () => {
  const override = mockOverride({set: {}})
  const {getByTestId} = render(<OverrideAssignTo override={override} variant="summary" />)
  const elem = getByTestId('OverrideAssignTo')
  expect(elem.innerHTML.includes('&nbsp')).toBeTruthy()
})

it('renders an OverrideAssignTo section summary', () => {
  const override = mockOverride(assignToSection)
  const {getByText} = render(<OverrideAssignTo override={override} variant="summary" />)
  expect(getByText('Section 8')).toBeInTheDocument()
})

it('renders an OverrideAssignTo section detail', () => {
  const override = mockOverride(assignToSection)
  const {getByText} = render(<OverrideAssignTo override={override} variant="detail" />)
  expect(getByText('Assign to:')).toBeInTheDocument()
  expect(getByText('Section 8')).toBeInTheDocument()
})

it('renders an OverrideAssignTo group summary', () => {
  const override = mockOverride(assignToGroup)
  const {getByText} = render(<OverrideAssignTo override={override} variant="summary" />)
  expect(getByText('Yo La Tengo')).toBeInTheDocument()
})

it('renders an OverrideAssignTo group summary with a group with no name', () => {
  const override = mockOverride(assignToGroupWithNoName)
  const {getByTestId} = render(<OverrideAssignTo override={override} variant="summary" />)
  const elem = getByTestId('OverrideAssignTo')
  expect(elem.innerHTML.includes('unnamed group')).toBeTruthy()
})

it('renders an OverrideAssignTo group detail', () => {
  const override = mockOverride(assignToGroup)
  const {getByText} = render(<OverrideAssignTo override={override} variant="detail" />)
  expect(getByText('Assign to:')).toBeInTheDocument()
  expect(getByText('Yo La Tengo')).toBeInTheDocument()
})

it('renders an OverrideAssignTo group detail with a group with no name', () => {
  const override = mockOverride(assignToGroupWithNoName)
  const {getByText} = render(<OverrideAssignTo override={override} variant="detail" />)
  expect(getByText('unnamed group')).toBeInTheDocument()
})

it('renders an OverrideAssignTo students summary', () => {
  const override = mockOverride(assignToStudents)
  const {getByText} = render(<OverrideAssignTo override={override} variant="summary" />)
  expect(getByText('Dweezil Zappa, Moon Zappa')).toBeInTheDocument()
})

it('renders an OverrideAssignTo students detail', () => {
  const override = mockOverride(assignToStudents)
  const {getByText} = render(<OverrideAssignTo override={override} variant="detail" />)
  expect(getByText('Assign to:')).toBeInTheDocument()
  expect(getByText('Dweezil Zappa')).toBeInTheDocument()
  expect(getByText('Moon Zappa')).toBeInTheDocument()
})
