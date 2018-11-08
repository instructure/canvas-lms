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
  ReactDOM.render(
    <AssignmentGroupModuleNav
      module={{name: 'Test Module', link: 'testmodulelink'}}
      assignmentGroup={{name: 'Test assignmentGroup', link: 'testassignmentgrouplink'}}
    />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(moduleLink.attr('href')).toEqual('testmodulelink')
  expect(assignmentGroupLink.attr('href')).toEqual('testassignmentgrouplink')
})

it('renders module and assignment group text correctly', () => {
  ReactDOM.render(
    <AssignmentGroupModuleNav
      module={{name: 'Test Module', link: 'testmodulelink'}}
      assignmentGroup={{name: 'Test assignmentGroup', link: 'testassignmentgrouplink'}}
    />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(moduleLink.text()).toEqual('Test Module')
  expect(assignmentGroupLink.text()).toEqual('Test assignmentGroup')
})

it('will not render module container if not present', () => {
  ReactDOM.render(
    <AssignmentGroupModuleNav
      assignmentGroup={{name: 'Test assignmentGroup', link: 'testassignmentgrouplink'}}
    />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(moduleLink).toHaveLength(0)
  expect(assignmentGroupLink.text()).toEqual('Test assignmentGroup')
})

it('will not render assignment group container if not present', () => {
  ReactDOM.render(
    <AssignmentGroupModuleNav module={{name: 'Test Module', link: 'testmodulelink'}} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(assignmentGroupLink).toHaveLength(0)
  expect(moduleLink.text()).toEqual('Test Module')
})

it('will render nothing if null props provided', () => {
  ReactDOM.render(
    <AssignmentGroupModuleNav module={null} assignmentGroup={null} />,
    document.getElementById('fixtures')
  )
  const moduleLink = $('[data-test-id="module-link"]')
  const assignmentGroupLink = $('[data-test-id="assignmentgroup-link"]')
  expect(assignmentGroupLink).toHaveLength(0)
  expect(moduleLink).toHaveLength(0)
})
