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
import {render, fireEvent, wait} from 'react-testing-library'
import {mockAssignment} from '../../test-utils'
import {CoreTeacherView} from '../TeacherView'

it('shows the message students who dialog when the unsubmitted button is clicked', async () => {
  const {getByText} = render(<CoreTeacherView data={{assignment: mockAssignment()}} />)
  fireEvent.click(getByText(/unsubmitted/))
  // waitForElement would be much more convenient and less redundant, but it
  // doesn't work with the MutationObserver that Canvas installs in
  // jest-setup.js. Figure this out later.
  await wait(() => getByText('Message Students Who'))
  expect(getByText('Message Students Who')).toBeInTheDocument()
})

it('shows the assignment', () => {
  const assignment = mockAssignment()
  const {getByText} = render(<CoreTeacherView data={{assignment}} />)
  expect(getByText(assignment.name)).toBeInTheDocument()
  expect(getByText(`${assignment.pointsPossible}`)).toBeInTheDocument()
  expect(getByText('Everyone')).toBeInTheDocument()
  expect(getByText('Due:', {exact: false})).toBeInTheDocument()
  expect(getByText('Available', {exact: false})).toBeInTheDocument()
})

// tests to implement somewhere
/* eslint-disable jest/no-disabled-tests */
it.skip('renders a loading screen when waiting on the initial query', () => {})
it.skip('renders a problem screen on a bad graphql query', () => {})
/* eslint-enable jest/no-disabled-tests */
