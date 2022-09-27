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
import {render, fireEvent} from '@testing-library/react'

let mockedSetOnSuccess = null
let mockedOnChangeSubmission = null

function mockContext(children) {
  return (
    <AlertManagerContext.Provider
      value={{
        setOnSuccess: mockedSetOnSuccess,
      }}
    >
      {children}
    </AlertManagerContext.Provider>
  )
}

async function createProps({attempt}) {
  const submission = await mockSubmission({Submission: {attempt}})
  const submission2 = await mockSubmission({Submission: {attempt: attempt + 1}})
  return {
    submission,
    allSubmissions: [submission, submission2],
    onChangeSubmission: mockedOnChangeSubmission,
  }
}

describe('Attempt', () => {
  beforeEach(() => {
    mockedSetOnSuccess = jest.fn().mockResolvedValue({})
    mockedOnChangeSubmission = jest.fn()
  })

  it('renders correctly', async () => {
    const props = await createProps({attempt: 1})
    const {getByDisplayValue} = render(mockContext(<AttemptSelect {...props} />))
    expect(getByDisplayValue('Attempt 1')).toBeInTheDocument()
  })

  it('renders attempt 0 as attempt 1', async () => {
    const submission = await mockSubmission({Submission: {attempt: 0}})
    const props = {
      submission,
      allSubmissions: [submission],
      onChangeSubmission: mockedOnChangeSubmission,
    }
    const {getByDisplayValue} = render(mockContext(<AttemptSelect {...props} />))
    expect(getByDisplayValue('Attempt 1')).toBeInTheDocument()
  })

  it('only renders a single "Attempt 1" option when there is attempt 0 and attempt 1', async () => {
    const submission = await mockSubmission({Submission: {attempt: 0}})
    const submission2 = await mockSubmission({Submission: {attempt: 1}})
    const props = {
      submission: submission2,
      allSubmissions: [submission, submission2],
      onChangeSubmission: mockedOnChangeSubmission,
    }
    const {getAllByText, getByTestId} = render(mockContext(<AttemptSelect {...props} />))
    const select = getByTestId('attemptSelect')
    fireEvent.click(select) // open select dropdown
    expect(getAllByText('Attempt 1').length).toBe(1)
  })

  it('renders the current submission attempt', async () => {
    const props = await createProps({attempt: 3})
    const {getByDisplayValue} = render(mockContext(<AttemptSelect {...props} />))
    expect(getByDisplayValue('Attempt 3')).toBeInTheDocument()
  })

  it('alerts the screenreader of the current displayed attempt', async () => {
    const props = await createProps({attempt: 1})
    render(mockContext(<AttemptSelect {...props} />))
    expect(mockedSetOnSuccess).toHaveBeenCalledWith('Now viewing Attempt 1')
  })

  it('changes the current attempt correctly', async () => {
    global.event = undefined // workaround bug in SimpleSelect that accesses the global event
    const props = await createProps({attempt: 1})
    const {getByText, getByTestId} = render(mockContext(<AttemptSelect {...props} />))
    const select = getByTestId('attemptSelect')
    fireEvent.click(select)
    fireEvent.click(getByText('Attempt 2'))
    expect(mockedOnChangeSubmission).toHaveBeenCalledWith(2)
  })
})
