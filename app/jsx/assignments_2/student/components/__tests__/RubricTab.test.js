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

import {MockedProvider} from 'react-apollo/test-utils'
import {mockQuery} from '../../mocks'
import React from 'react'
import {render} from '@testing-library/react'
import Rubric from '../../../../rubrics/Rubric'
import {RUBRIC_QUERY} from '../../graphqlData/Queries'

async function mockRubric(overrides = {}) {
  const variables = {assignmentID: '1'}
  const result = await mockQuery(RUBRIC_QUERY, overrides, variables)
  return result.data.assignment.rubric
}

describe('RubricTab', () => {
  it('contains the rubric criteria heading', async () => {
    const rubric = await mockRubric({})
    const {getByText} = render(
      <MockedProvider>
        <Rubric rubric={rubric} />
      </MockedProvider>
    )
    expect(getByText('Criteria')).toBeInTheDocument()
  })

  it('contains the rubric ratings heading', async () => {
    const rubric = await mockRubric({})
    const {getByText} = render(
      <MockedProvider>
        <Rubric rubric={rubric} />
      </MockedProvider>
    )
    expect(getByText('Ratings')).toBeInTheDocument()
  })

  it('contains the rubric points heading', async () => {
    const rubric = await mockRubric({})
    const {getByText} = render(
      <MockedProvider>
        <Rubric rubric={rubric} />
      </MockedProvider>
    )
    expect(getByText('Pts')).toBeInTheDocument()
  })
})
