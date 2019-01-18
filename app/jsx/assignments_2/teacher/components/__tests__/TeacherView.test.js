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
import {render, fireEvent, wait, waitForElement} from 'react-testing-library'
import {mockAssignment, findInputForLabel} from '../../test-utils'
import TeacherView from '../TeacherView'
import {queryAssignment, setWorkflow} from '../../api'

jest.mock('../../api')

async function renderTeacherView(assignment = mockAssignment()) {
  queryAssignment.mockReturnValueOnce({data: {assignment}})
  const result = render(<TeacherView assignmentLid={assignment.lid} />)
  await wait() // wait a tick for the api promise to resolve
  return result
}

it('shows the message students who dialog when the unsubmitted button is clicked', async () => {
  const {getByText} = await renderTeacherView()
  fireEvent.click(getByText(/unsubmitted/))
  expect(await waitForElement(() => getByText('Message Students Who'))).toBeInTheDocument()
})

it('shows the assignment', async () => {
  const assignment = mockAssignment()
  const {getByText} = await renderTeacherView(assignment)
  expect(await waitForElement(() => getByText(assignment.name))).toBeInTheDocument()
  expect(await waitForElement(() => getByText(`${assignment.pointsPossible}`))).toBeInTheDocument()
  expect(await waitForElement(() => getByText('Everyone'))).toBeInTheDocument()
  expect(await waitForElement(() => getByText('Due:', {exact: false}))).toBeInTheDocument()
  expect(await waitForElement(() => getByText('Available', {exact: false}))).toBeInTheDocument()
})

it('unpublishes the assignment', async () => {
  const assignment = mockAssignment()
  const {getByText, container} = await renderTeacherView(assignment)
  const publish = getByText('publish', {exact: false})
  fireEvent.click(findInputForLabel(publish, container))
  expect(setWorkflow).toHaveBeenCalledWith(assignment, 'unpublished')
})

it('publishes the assignment', async () => {
  const assignment = mockAssignment({state: 'unpublished'})
  const {getByText, container} = await renderTeacherView(assignment)
  const publish = getByText('publish', {exact: false})
  fireEvent.click(findInputForLabel(publish, container))
  expect(setWorkflow).toHaveBeenCalledWith(assignment, 'published')
})

// tests to implement somewhere
/* eslint-disable jest/no-disabled-tests */
it.skip('renders a loading screen when waiting on the initial query', () => {})
it.skip('renders a problem screen on a bad graphql query', () => {})
/* eslint-enable jest/no-disabled-tests */
