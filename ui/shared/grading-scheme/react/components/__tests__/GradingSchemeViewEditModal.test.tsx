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
import {render} from '@testing-library/react'
import {
  GradingSchemeViewEditModal,
  type GradingSchemeViewEditModalProps,
} from '../GradingSchemeViewEditModal'
import {AccountGradingSchemes, DefaultGradingScheme} from './fixtures'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('Grading Schemes View Edit Tests', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  const renderGradingSchemesManagement = (props: Partial<GradingSchemeViewEditModalProps> = {}) => {
    return render(
      <GradingSchemeViewEditModal
        contextId="1"
        contextType="Course"
        gradingSchemeId="1"
        archivedGradingSchemesEnabled={false}
        onCancel={() => {}}
        onUpdate={() => {}}
        onDelete={() => {}}
        {...props}
      />,
    )
  }

  it('should render selected grading scheme', async () => {
    server.use(
      http.get('/courses/:contextId/grading_schemes/:schemeId', () =>
        HttpResponse.json(AccountGradingSchemes[0]),
      ),
      http.get('/courses/:contextId/grading_schemes/default', () =>
        HttpResponse.json(DefaultGradingScheme),
      ),
    )
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId('grading_scheme_1_edit_button')).toBeInTheDocument()
  })

  it('should not disable course grading scheme buttons', async () => {
    server.use(
      http.get('/courses/:contextId/grading_schemes/:schemeId', () =>
        HttpResponse.json(AccountGradingSchemes[0]),
      ),
      http.get('/courses/:contextId/grading_schemes/default', () =>
        HttpResponse.json(DefaultGradingScheme),
      ),
    )
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId('grading_scheme_1_edit_button')).not.toBeDisabled()
  })

  it('should disable Account grading scheme buttons when contextType is Course', async () => {
    server.use(
      http.get('/courses/:contextId/grading_schemes/:schemeId', () =>
        HttpResponse.json(AccountGradingSchemes[1]),
      ),
      http.get('/courses/:contextId/grading_schemes/default', () =>
        HttpResponse.json(DefaultGradingScheme),
      ),
    )
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId('grading_scheme_2_edit_button')).toBeDisabled()
  })

  it('should not disable Account grading scheme buttons when contextType is Account', async () => {
    server.use(
      http.get('/accounts/:contextId/grading_schemes/:schemeId', () =>
        HttpResponse.json(AccountGradingSchemes[1]),
      ),
      http.get('/accounts/:contextId/grading_schemes/default', () =>
        HttpResponse.json(DefaultGradingScheme),
      ),
    )
    const {getByTestId} = renderGradingSchemesManagement({contextType: 'Account'})

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId('grading_scheme_2_edit_button')).not.toBeDisabled()
  })
})
