/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {fireEvent, waitForElement} from 'react-testing-library'
import {renderTeacherView} from './integration-utils'
import {mockAssignment, waitForNoElement} from '../../../test-utils'

jest.mock('jsx/shared/rce/RichContentEditor')

// TODO: some of these tests are essentially duplicates of the delete dialog tests. Should unify somehow.
describe.skip('MessageStudentsWho integration', () => {
  it('shows the message students who dialog when the unsubmitted button is clicked', async () => {
    const {getByText, queryByText} = await renderTeacherView()
    expect(queryByText('Message Students Who...')).toBeNull()
    fireEvent.click(getByText(/unsubmitted/i))
    expect(await waitForElement(() => getByText('Message Students Who...'))).toBeInTheDocument()
  })

  it('shows the message students who dialog when the message students who button is clicked', async () => {
    const {getByText} = await renderTeacherView(mockAssignment({submissionTypes: ['none']}))
    fireEvent.click(getByText(/message students/i))
    expect(await waitForElement(() => getByText('Message Students Who...'))).toBeInTheDocument()
  })

  it('closes message students who when cancel is clicked', async () => {
    const {getByText} = await renderTeacherView()
    fireEvent.click(getByText(/unsubmitted/i))
    await waitForElement(() => getByText('Message Students Who...'))
    fireEvent.click(getByText(/cancel/i))
    await waitForNoElement(() => getByText('Message Students Who...'))
  })

  it('closes message students who when the close button is clicked', async () => {
    const {getByText, getByTestId} = await renderTeacherView()
    fireEvent.click(getByText(/unsubmitted/i))
    await waitForElement(() => getByText('Message Students Who...'))
    fireEvent.click(getByTestId('confirm-dialog-close-button'))
    await waitForNoElement(() => getByText('Message Students Who...'))
  })

  /* eslint-disable jest/no-disabled-tests */
  describe.skip('sending messages', () => {
    it('calls api to message remaining students when "send" is clicked', () => {
      // check set of students, subject, and message parameters
    })

    it('disables the dialog while sending is in progress', () => {
      // make the api call wait until we say it can finish
    })

    it('dismisses the dialog and sr-flashes success when the save finishes successfully', () => {})

    it('renders errors, does not dismiss the dialog, and reenables it when the save fails', () => {})
  })
  /* eslint-enable jest/no-disabled-tests */
})
