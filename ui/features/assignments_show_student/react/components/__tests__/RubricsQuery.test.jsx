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

import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import React from 'react'
import {render} from '@testing-library/react'
import RubricsQuery from '../RubricsQuery'
import {RUBRIC_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {useAllPages} from '@canvas/query'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/query', () => ({
  useAllPages: jest.fn(),
}))

async function makeMocks() {
  const variables = {
    courseID: '1',
    assignmentLid: '1',
    submissionID: '1',
    submissionAttempt: 0,
  }

  const overrides = {
    Node: {__typename: 'Assignment'},
    Assignment: {rubric: {}},
    Rubric: {criteria: [{}]},
    Submission: {rubricAssessmentsConnection: []},
    HtmlEncodedString: () => 'Mocked HTML encoded string',
  }

  const result = await mockQuery(RUBRIC_QUERY, overrides, variables)
  return [
    {
      request: {
        query: RUBRIC_QUERY,
        variables,
      },
      result,
    },
  ]
}

async function makeProps() {
  const props = await mockAssignmentAndSubmission({
    Assignment: {
      rubric: {},
    },
  })
  return props
}

describe('RubricsQuery', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user: {id: '1', display_name: 'Test User'},
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the rubric tab', async () => {
    useAllPages.mockReturnValue({
      data: {pages: []},
      isError: false,
      isLoading: false,
    })
    const mocks = await makeMocks()
    const props = await makeProps()
    const {findByTestId} = render(
      <MockedProvider mocks={mocks}>
        <RubricsQuery {...props} />
      </MockedProvider>,
    )
    expect(await findByTestId('rubric-tab')).toBeInTheDocument()
  })

  it('renders an error when the query fails', async () => {
    useAllPages.mockReturnValue({
      data: {},
      isError: true,
      isLoading: false,
    })
    const props = await makeProps()
    const mocks = await makeMocks()
    mocks[0].error = new Error('aw shucks')
    const {findByText} = render(
      <MockedProvider mocks={mocks}>
        <RubricsQuery {...props} />
      </MockedProvider>,
    )
    expect(await findByText('Sorry, Something Broke')).toBeInTheDocument()
  })

  it('renders the loading indicator when making a query', async () => {
    useAllPages.mockReturnValue({
      data: {},
      isError: false,
      isLoading: true,
    })
    const mocks = await makeMocks()
    const props = await makeProps()
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <RubricsQuery {...props} />
      </MockedProvider>,
    )
    expect(getByText('Loading')).toBeInTheDocument()
  })
})
