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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import AttemptSelect from '../AttemptSelect'
import {mockSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

type Submission = any // Using any since mockSubmission returns an unknown shape

let mockedSetOnSuccess: any
let mockedOnChangeSubmission: any

function mockContext(children: React.ReactNode) {
  return (
    <AlertManagerContext.Provider
      value={{
        setOnSuccess: mockedSetOnSuccess,
        setOnFailure: vi.fn(),
      }}
    >
      {children}
    </AlertManagerContext.Provider>
  )
}

async function createProps({attempt}: {attempt: number}) {
  const submission = (await mockSubmission([{Submission: {attempt}}])) as Submission
  const submission2 = (await mockSubmission([{Submission: {attempt: attempt + 1}}])) as Submission
  return {
    submission,
    allSubmissions: [submission, submission2],
    onChangeSubmission: mockedOnChangeSubmission,
  }
}

describe('Attempt', () => {
  beforeEach(() => {
    mockedSetOnSuccess = vi.fn().mockResolvedValue({})
    mockedOnChangeSubmission = vi.fn()
  })

  it('renders correctly', async () => {
    const props = await createProps({attempt: 1})
    render(mockContext(<AttemptSelect {...props} />))
    expect(screen.getByDisplayValue('Attempt 1')).toBeInTheDocument()
  })

  it('renders attempt 0 as attempt 1', async () => {
    const submission = (await mockSubmission([{Submission: {attempt: 0}}])) as Submission
    const props = {
      submission,
      allSubmissions: [submission],
      onChangeSubmission: mockedOnChangeSubmission,
    }
    render(mockContext(<AttemptSelect {...props} />))
    expect(screen.getByDisplayValue('Attempt 1')).toBeInTheDocument()
  })

  it('only renders a single "Attempt 1" option when there is attempt 0 and attempt 1', async () => {
    const submission = (await mockSubmission([{Submission: {attempt: 0}}])) as Submission
    const submission2 = (await mockSubmission([{Submission: {attempt: 1}}])) as Submission
    const props = {
      submission: submission2,
      allSubmissions: [submission, submission2],
      onChangeSubmission: mockedOnChangeSubmission,
    }
    render(mockContext(<AttemptSelect {...props} />))
    const select = screen.getByTestId('attemptSelect')
    await userEvent.click(select)
    expect(screen.getAllByText('Attempt 1')).toHaveLength(1)
  })

  it('nothing happens when user clicks on Attempt 1 when there is only one submission', async () => {
    const submission = (await mockSubmission([{Submission: {attempt: 1}}])) as Submission
    const props = {
      submission,
      allSubmissions: [submission],
      onChangeSubmission: mockedOnChangeSubmission,
    }
    render(mockContext(<AttemptSelect {...props} />))
    const select = screen.getByTestId('attemptSelect')
    await userEvent.click(select)
    const attempt1 = screen.getByText('Attempt 1')
    await userEvent.click(attempt1)

    // Verify the callback was called with the correct attempt number
    expect(mockedOnChangeSubmission).toHaveBeenCalledWith(1)
    // Verify no error was thrown (component didn't crash)
    expect(screen.getByTestId('attemptSelect')).toBeInTheDocument()
  })

  it('handles clicking on Attempt 1 when submission has attempt 0 (unsubmitted)', async () => {
    const submission = (await mockSubmission([{Submission: {attempt: 0}}])) as Submission
    const props = {
      submission,
      allSubmissions: [submission],
      onChangeSubmission: mockedOnChangeSubmission,
    }
    render(mockContext(<AttemptSelect {...props} />))
    const select = screen.getByTestId('attemptSelect')
    await userEvent.click(select)
    const attempt1 = screen.getByText('Attempt 1')
    await userEvent.click(attempt1)

    // Verify the callback was called with attempt 0 (the actual submission attempt)
    expect(mockedOnChangeSubmission).toHaveBeenCalledWith(0)
    // Verify no error was thrown (component didn't crash)
    expect(screen.getByTestId('attemptSelect')).toBeInTheDocument()
  })

  it('renders the current submission attempt', async () => {
    const props = await createProps({attempt: 3})
    render(mockContext(<AttemptSelect {...props} />))
    expect(screen.getByDisplayValue('Attempt 3')).toBeInTheDocument()
  })

  it('alerts the screenreader of the current displayed attempt', async () => {
    const props = await createProps({attempt: 1})
    render(mockContext(<AttemptSelect {...props} />))
    expect(mockedSetOnSuccess).toHaveBeenCalledWith('Now viewing Attempt 1')
  })

  it('changes the current attempt correctly', async () => {
    global.event = undefined // workaround bug in SimpleSelect that accesses the global event
    const user = userEvent.setup()
    const props = await createProps({attempt: 1})
    render(mockContext(<AttemptSelect {...props} />))
    const select = screen.getByTestId('attemptSelect')
    await user.click(select)
    await user.click(screen.getByText('Attempt 2'))
    expect(mockedOnChangeSubmission).toHaveBeenCalledWith(2)
  })
})
