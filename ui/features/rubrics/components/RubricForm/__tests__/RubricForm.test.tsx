/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import Router from 'react-router'
import {BrowserRouter} from 'react-router-dom'
import {render} from '@testing-library/react'
import {QueryProvider, queryClient} from '@canvas/query'
import {RubricForm} from '../index'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'

jest.mock('react-router', () => ({
  ...jest.requireActual('react-router'),
  useParams: jest.fn(),
}))

describe('RubricForm Tests', () => {
  beforeAll(() => {
    jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})
  })

  const renderComponent = () => {
    return render(
      <QueryProvider>
        <BrowserRouter>
          <RubricForm />
        </BrowserRouter>
      </QueryProvider>
    )
  }

  describe('without rubricId', () => {
    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId, getByText} = renderComponent()
      expect(getByText('Create New Rubric')).toBeInTheDocument()
      expect(getByTestId('rubric-form-title')).toHaveValue('')
    })
  })

  describe('with rubricId', () => {
    beforeAll(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({rubricId: '1'})
    })

    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId} = renderComponent()
      expect(getByTestId('rubric-form-title')).toHaveValue('Rubric 1')
    })
  })
})
