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

import {mockAssignmentAndSubmission, mockQuery} from '../../mocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {render, waitForElement} from '@testing-library/react'
import RubricTab from '../RubricTab'
import {RUBRIC_QUERY} from '../../graphqlData/Queries'

function gradedOverrides() {
  return {
    Submission: () => ({
      rubricAssessmentsConnection: {
        nodes: [{}]
      }
    }),
    Course: () => ({
      account: {
        proficiencyRatingsConnection: {
          nodes: [{}]
        }
      }
    })
  }
}

function ungradedOverrides() {
  return {
    Submission: () => ({rubricAssessmentsConnection: null}),
    Course: () => ({
      account: {
        proficiencyRatingsConnection: null
      }
    })
  }
}

async function makeMocks(opts = {}) {
  const variables = {
    courseID: '1',
    rubricID: '1',
    submissionID: '1',
    submissionAttempt: 0
  }

  const overrides = opts.graded ? gradedOverrides() : ungradedOverrides()
  const allOverrides = [
    {
      Node: () => ({__typename: 'Rubric'}),
      Rubric: () => ({
        criteria: [{}]
      }),
      ...overrides
    }
  ]

  const result = await mockQuery(RUBRIC_QUERY, allOverrides, variables)
  return [
    {
      request: {
        query: RUBRIC_QUERY,
        variables
      },
      result
    }
  ]
}

async function makeProps() {
  const props = await mockAssignmentAndSubmission({
    Assignment: () => ({
      rubric: {}
    })
  })
  return props
}

describe('RubricTab', () => {
  describe('ungraded rubric', () => {
    it('contains the rubric criteria heading', async () => {
      const mocks = await makeMocks({graded: false})
      const props = await makeProps()
      const {getAllByText} = render(
        <MockedProvider mocks={mocks}>
          <RubricTab {...props} />
        </MockedProvider>
      )
      expect(await waitForElement(() => getAllByText('Criteria')[1])).toBeInTheDocument()
    })

    it('contains the rubric ratings heading', async () => {
      const mocks = await makeMocks({graded: false})
      const props = await makeProps()
      const {getAllByText} = render(
        <MockedProvider mocks={mocks}>
          <RubricTab {...props} />
        </MockedProvider>
      )
      expect(await waitForElement(() => getAllByText('Ratings')[1])).toBeInTheDocument()
    })

    it('contains the rubric points heading', async () => {
      const mocks = await makeMocks({graded: false})
      const props = await makeProps()
      const {getAllByText} = render(
        <MockedProvider mocks={mocks}>
          <RubricTab {...props} />
        </MockedProvider>
      )
      expect(await waitForElement(() => getAllByText('Pts')[1])).toBeInTheDocument()
    })
  })

  describe('graded rubric', () => {
    it('displays comments', async () => {
      const mocks = await makeMocks({graded: true})
      const props = await makeProps()
      const {getAllByText} = render(
        <MockedProvider mocks={mocks}>
          <RubricTab {...props} />
        </MockedProvider>
      )
      expect(await waitForElement(() => getAllByText('Comments')[0])).toBeInTheDocument()
    })

    it('displays the points for a criteria', async () => {
      const mocks = await makeMocks({graded: true})
      const props = await makeProps()
      const {getByText} = render(
        <MockedProvider mocks={mocks}>
          <RubricTab {...props} />
        </MockedProvider>
      )
      expect(await waitForElement(() => getByText('6 / 6 pts'))).toBeInTheDocument()
    })

    it('displays the total points for the rubric assessment', async () => {
      const mocks = await makeMocks({graded: true})
      const props = await makeProps()
      const {getByText} = render(
        <MockedProvider mocks={mocks}>
          <RubricTab {...props} />
        </MockedProvider>
      )
      expect(await waitForElement(() => getByText('Total Points: 10'))).toBeInTheDocument()
    })
  })
})
