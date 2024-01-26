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
import {fireEvent, render} from '@testing-library/react'
import {QueryProvider, queryClient} from '@canvas/query'
import {RubricForm} from '../index'
import {RUBRICS_QUERY_RESPONSE} from './fixtures'
import * as RubricFormQueries from '../../../queries/RubricFormQueries'

jest.mock('react-router', () => ({
  ...jest.requireActual('react-router'),
  useParams: jest.fn(),
}))

const saveRubricMock = jest.fn()
jest.mock('../../../queries/RubricFormQueries', () => ({
  ...jest.requireActual('../../../queries/RubricFormQueries'),
  saveRubric: () => saveRubricMock,
}))

describe('RubricForm Tests', () => {
  beforeEach(() => {
    jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})
  })

  afterEach(() => {
    jest.resetAllMocks()
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

  const getSRAlert = () => document.querySelector('#flash_screenreader_holder')?.textContent

  describe('without rubricId', () => {
    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId, getByText} = renderComponent()
      expect(getByText('Create New Rubric')).toBeInTheDocument()
      expect(getByTestId('rubric-form-title')).toHaveValue('')
    })
  })

  describe('with rubricId', () => {
    beforeEach(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({rubricId: '1'})
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    it('loads rubric data and populates appropriate fields', () => {
      queryClient.setQueryData(['fetch-rubric-1'], RUBRICS_QUERY_RESPONSE)

      const {getByTestId} = renderComponent()
      expect(getByTestId('rubric-form-title')).toHaveValue('Rubric 1')
    })
  })

  describe('save rubric', () => {
    beforeEach(() => {
      jest.spyOn(Router, 'useParams').mockReturnValue({accountId: '1'})
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    it('save button is disabled when title is empty', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is disabled when title is whitespace', () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: ' '}})
      expect(getByTestId('save-rubric-button')).toBeDisabled()
    })

    it('save button is enabled when title is not empty', () => {
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      expect(getByTestId('save-rubric-button')).toBeEnabled()
    })

    it('will navigate back to /rubrics after successfully saving', async () => {
      jest
        .spyOn(RubricFormQueries, 'saveRubric')
        .mockImplementation(() => Promise.resolve({id: '1', title: 'Rubric 1'}))
      const {getByTestId} = renderComponent()
      const titleInput = getByTestId('rubric-form-title')
      fireEvent.change(titleInput, {target: {value: 'Rubric 1'}})
      fireEvent.click(getByTestId('save-rubric-button'))

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getSRAlert()).toEqual('Rubric saved successfully')
    })
  })
})
