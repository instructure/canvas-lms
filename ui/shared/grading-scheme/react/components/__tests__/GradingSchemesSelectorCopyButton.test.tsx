/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import {AccountGradingSchemes, DefaultGradingScheme, GradingSchemeSummaries} from './fixtures'
import {GradingSchemesSelector, type GradingSchemesSelectorProps} from '../GradingSchemesSelector'
import type {GradingScheme} from '@canvas/grading-scheme/gradingSchemeApiModel'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer(
  http.get('*/grading_scheme_summaries', () => HttpResponse.json(GradingSchemeSummaries)),
  http.get('*/grading_schemes/default', () => HttpResponse.json(DefaultGradingScheme)),
  http.get('*/grading_schemes/:id', ({params, request}) => {
    const url = new URL(request.url)
    // Don't match the default endpoint
    if (url.pathname.endsWith('/default')) return
    const matchedScheme = AccountGradingSchemes.find(scheme => scheme.id === params.id)
    if (matchedScheme) {
      return HttpResponse.json(matchedScheme)
    }
    return new HttpResponse(null, {status: 404})
  }),
  http.post('*/grading_schemes', async ({request}) => {
    const body = (await request.json()) as Record<string, any>
    const newScheme: Partial<GradingScheme> = {
      ...body,
      id: '1000',
      context_id: '1',
      context_type: 'Course',
      assessed_assignment: false,
      permissions: {manage: true},
      context_name: 'Test Course',
      workflow_state: 'active',
    }
    return HttpResponse.json(newScheme)
  }),
  http.put('*/grading_schemes/:id', () => new HttpResponse(null, {status: 200})),
  http.delete('*/grading_schemes/:id', () => new HttpResponse(null, {status: 200})),
)

function renderGradingSchemesSelector(props: Partial<GradingSchemesSelectorProps> = {}) {
  const onChange = vi.fn()

  const utils = render(
    <GradingSchemesSelector
      canManage={true}
      canSet={true}
      contextType="Course"
      contextId="1"
      archivedGradingSchemesEnabled={true}
      onChange={onChange}
      {...props}
    />,
  )

  return {
    ...utils,
    onChange,
  }
}

describe('GradingSchemesSelector copy button tests', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => {
    server.resetHandlers()
  })

  it('should open the duplicate modal when the copy button is clicked for the default scheme', async () => {
    const {getByTestId} = renderGradingSchemesSelector()
    await new Promise(resolve => setTimeout(resolve, 0))
    const dropdown = getByTestId('grading-schemes-selector-dropdown')
    fireEvent.click(dropdown)
    const defaultScheme = getByTestId('grading-schemes-selector-default-option')
    fireEvent.click(defaultScheme)
    const copyButton = getByTestId('grading-schemes-selector-copy-button')
    fireEvent.click(copyButton)
    expect(getByTestId('grading-scheme-duplicate-modal')).toBeInTheDocument()
  })

  it('should open the duplicate modal when the copy button is clicked for a course scheme', async () => {
    const {getByTestId} = renderGradingSchemesSelector()
    await new Promise(resolve => setTimeout(resolve, 0))
    const dropdown = getByTestId('grading-schemes-selector-dropdown')
    fireEvent.click(dropdown)
    const scheme = getByTestId('grading-schemes-selector-option-1')
    fireEvent.click(scheme)
    const copyButton = getByTestId('grading-schemes-selector-copy-button')
    fireEvent.click(copyButton)
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId('grading-scheme-duplicate-modal')).toBeInTheDocument()
  })

  it('should make an api call when the duplicate button is clicked and then open the edit modal', async () => {
    let createData: any = null
    server.use(
      http.post('/courses/:contextId/grading_schemes', async ({request}) => {
        createData = await request.json()
        const newScheme: Partial<GradingScheme> = {
          ...createData,
          id: '1000',
          context_id: '1',
          context_type: 'Course',
          assessed_assignment: false,
          permissions: {manage: true},
          context_name: 'Test Course',
          workflow_state: 'active',
        }
        return HttpResponse.json(newScheme)
      }),
    )

    const {getByTestId, findByTestId} = renderGradingSchemesSelector()
    const dropdown = await findByTestId('grading-schemes-selector-dropdown')
    fireEvent.click(dropdown)
    const copyButton = getByTestId('grading-schemes-selector-copy-button')
    fireEvent.click(copyButton)
    const duplicateButton = await findByTestId('grading-scheme-duplicate-modal-duplicate-button')
    fireEvent.click(duplicateButton)
    await findByTestId('grading-scheme-edit-modal')
    expect(createData).toEqual({
      title: 'Default Canvas Grading Scheme Copy',
      points_based: false,
      scaling_factor: 1,
      data: DefaultGradingScheme.data,
    })
  })
})
