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
import ReactDOM from 'react-dom'
import $ from 'jquery'

import {mockAssignment} from '../../test-utils'
import AssignmentGroupModuleNav from '../AssignmentGroupModuleNav'

beforeAll(() => {
  const found = document.getElementById('fixtures')
  if (!found) {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)
  }
})

afterEach(() => {
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

it('renders module and assignment group links correctly', () => {
  const assignment = mockAssignment({
    assignmentGroup: {name: 'Test assignmentGroup'},
    modules: [{id: 1, name: 'Test Module'}],
    env: {
      assignmentUrl: 'testassignmentgrouplink',
      moduleUrl: 'testmodulelink'
    }
  })
  ReactDOM.render(
    <AssignmentGroupModuleNav assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(moduleLink.attr('href')).toEqual('testmodulelink')
  expect(assignmentGroupLink.attr('href')).toEqual('testassignmentgrouplink')
})

it('renders module and assignment group text correctly', () => {
  const assignment = mockAssignment({
    modules: [{id: 1, name: 'Test Module'}],
    assignmentGroup: {name: 'Test assignmentGroup'}
  })
  ReactDOM.render(
    <AssignmentGroupModuleNav assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(moduleLink.text()).toEqual('Test Module')
  expect(assignmentGroupLink.text()).toEqual('Test assignmentGroup')
})

it('will not render module container if not present', () => {
  const assignment = mockAssignment({
    modules: [],
    assignmentGroup: {name: 'Test assignmentGroup'}
  })
  ReactDOM.render(
    <AssignmentGroupModuleNav assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(moduleLink).toHaveLength(0)
  expect(assignmentGroupLink.text()).toEqual('Test assignmentGroup')
})

it('will not render assignment group container if not present', () => {
  const assignment = mockAssignment({
    modules: [{id: 1, name: 'Test Module'}],
    assignmentGroup: null
  })
  ReactDOM.render(
    <AssignmentGroupModuleNav assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(assignmentGroupLink).toHaveLength(0)
  expect(moduleLink.text()).toEqual('Test Module')
})

it('will render nothing if null props provided', () => {
  const assignment = mockAssignment({modules: [], assignmentGroup: null})
  ReactDOM.render(
    <AssignmentGroupModuleNav assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(assignmentGroupLink).toHaveLength(0)
  expect(moduleLink).toHaveLength(0)
})

it('renders multiple modules', () => {
  const assignment = mockAssignment({
    modules: [{id: 1, name: 'Test Module 1'}, {id: 2, name: 'Test Module 2'}],
    assignmentGroup: null
  })
  ReactDOM.render(
    <AssignmentGroupModuleNav assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  expect(moduleLink).toHaveLength(2)
  expect(moduleLink.eq(0).text()).toEqual('Test Module 1')
  expect(moduleLink.eq(1).text()).toEqual('Test Module 2')
})

it('limits the maximum number of modules rendered', () => {
  const assignment = mockAssignment({
    modules: [
      {id: 1, name: 'Test Module 1'},
      {id: 2, name: 'Test Module 2'},
      {id: 3, name: 'Test Module 3'},
      {id: 4, name: 'Test Module 4'}
    ],
    assignmentGroup: null
  })
  ReactDOM.render(
    <AssignmentGroupModuleNav assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  expect(moduleLink).toHaveLength(3)
  expect(moduleLink.eq(0).text()).toEqual('Test Module 1')
  expect(moduleLink.eq(1).text()).toEqual('Test Module 2')
  expect(moduleLink.eq(2).text()).toEqual('More Modules')
})
