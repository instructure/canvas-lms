/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import {render} from '@testing-library/react'
import GradingResults, {type GradingResultsComponentProps} from '..'
import {defaultStudentSubmissions, gradingResultsDefaultProps} from './fixtures'
import {setupCanvasQueries} from '../../__tests__/fixtures'
import {MockedQueryProvider} from '@canvas/test-utils/query'

jest.mock('@canvas/do-fetch-api-effect/apiRequest', () => ({
  executeApiRequest: jest.fn(),
}))

import fakeENV from '@canvas/test-utils/fakeENV'

const renderGradingResults = (props: GradingResultsComponentProps) => {
  return render(
    <MockedQueryProvider>
      <GradingResults {...props} />
    </MockedQueryProvider>,
  )
}

describe('Grading Results Tests', () => {
  beforeEach(() => {
    fakeENV.setup()
    $.subscribe = jest.fn()
    setupCanvasQueries()
    jest.clearAllMocks()
  })

  afterEach(() => {
    fakeENV.teardown()
  })
  describe('status pills', () => {
    it('renders late pill', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            late: true,
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission-status-pill')).toHaveTextContent('LATE')
    })
    it('renders missing pill', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            missing: true,
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission-status-pill')).toHaveTextContent('MISSING')
    })
    it('renders extended pill', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            latePolicyStatus: 'extended',
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission-status-pill')).toHaveTextContent('EXTENDED')
    })
    it('renders custom status pill and makes text upper case', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            customGradeStatus: 'carrot',
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission-status-pill')).toHaveTextContent('CARROT')
    })
    it('renders custom status pill even if other statuses are true', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            late: true,
            missing: true,
            latePolicyStatus: 'extended',
            customGradeStatus: 'POTATO',
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission-status-pill')).toHaveTextContent('POTATO')
    })
  })
})
