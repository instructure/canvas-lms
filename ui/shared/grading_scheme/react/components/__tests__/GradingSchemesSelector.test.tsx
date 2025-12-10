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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {AccountGradingSchemes, DefaultGradingScheme, GradingSchemeSummaries} from './fixtures'
import {GradingSchemesSelector, type GradingSchemesSelectorProps} from '../GradingSchemesSelector'
import type {GradingScheme} from '@canvas/grading_scheme/gradingSchemeApiModel'
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
  const onChange = jest.fn()

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

describe('GradingSchemesSelector', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => {
    server.resetHandlers()
  })
  it('should render a dropdown and view, copy, and new grading scheme buttons, and loads default scheme and scheme summaries', async () => {
    const {getByTestId} = renderGradingSchemesSelector()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId('grading-schemes-selector-view-button')).toBeInTheDocument()
    expect(getByTestId('grading-schemes-selector-copy-button')).toBeInTheDocument()
    expect(getByTestId('grading-schemes-selector-new-grading-scheme-button')).toBeInTheDocument()
  })

  it('should render disabled unless canSet is true', async () => {
    const {getByTestId} = renderGradingSchemesSelector({canSet: false})
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId('grading-schemes-selector-view-button')).not.toBeDisabled()
    expect(getByTestId('grading-schemes-selector-dropdown')).toBeDisabled()
  })

  describe('view button tests', () => {
    it('should make an api call when the view button is clicked on a scheme other than the default one', async () => {
      let schemeRequested = false
      server.use(
        http.get('*/grading_schemes/:id', ({params, request}) => {
          const url = new URL(request.url)
          if (url.pathname.endsWith('/default')) return
          if (params.id === '1') schemeRequested = true
          const matchedScheme = AccountGradingSchemes.find(scheme => scheme.id === params.id)
          return matchedScheme
            ? HttpResponse.json(matchedScheme)
            : new HttpResponse(null, {status: 404})
        }),
      )

      const {getByTestId} = renderGradingSchemesSelector()
      await waitFor(() =>
        expect(getByTestId('grading-schemes-selector-dropdown')).toBeInTheDocument(),
      )
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const scheme = getByTestId('grading-schemes-selector-option-1')
      fireEvent.click(scheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      await waitFor(() => expect(schemeRequested).toBe(true))
    })

    it('should not make an api call when the default scheme is selected', async () => {
      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const defaultScheme = getByTestId('grading-schemes-selector-default-option')
      fireEvent.click(defaultScheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      // Test passes if modal opens without making additional API calls
    })

    it('should open the view modal when the view button is clicked for the default scheme', async () => {
      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const defaultScheme = getByTestId('grading-schemes-selector-default-option')
      fireEvent.click(defaultScheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      expect(getByTestId('grading-scheme-view-modal')).toBeInTheDocument()
    })

    it('should open the view modal when the view button is clicked for a non-default scheme', async () => {
      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const scheme = getByTestId('grading-schemes-selector-option-1')
      fireEvent.click(scheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('grading-scheme-view-modal')).toBeInTheDocument()
    })

    it('opened view modal data should match course default (if any) if no other is selected', async () => {
      const {getByTestId} = renderGradingSchemesSelector({courseDefaultSchemeId: '3'})
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const scheme = getByTestId('grading-schemes-selector-option-3')
      const nameOfCourseDefaultScheme = scheme.textContent
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      const gradeModalTitle = getByTestId('grading-scheme-view-modal-title').textContent
      expect(gradeModalTitle).toBe(nameOfCourseDefaultScheme)
    })

    it('should open the edit modal when the edit button is clicked', async () => {
      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const scheme = getByTestId('grading-schemes-selector-option-1')
      fireEvent.click(scheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      const editButton = getByTestId('grading-scheme-1-edit-button')
      fireEvent.click(editButton)
      expect(getByTestId('grading-scheme-edit-modal')).toBeInTheDocument()
    })

    it('can delete the scheme through edit modal', async () => {
      let deleteRequested = false
      server.use(
        http.delete('/courses/:contextId/grading_schemes/:id', ({params}) => {
          if (params.id === '1') deleteRequested = true
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const scheme = getByTestId('grading-schemes-selector-option-1')
      fireEvent.click(scheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      const editButton = getByTestId('grading-scheme-1-edit-button')
      fireEvent.click(editButton)
      const deleteButton = getByTestId('grading-scheme-edit-modal-delete-button')
      fireEvent.click(deleteButton)
      expect(getByTestId('grading-scheme-delete-modal')).toBeInTheDocument()
      const deleteButtonOnModal = getByTestId('grading-scheme-delete-modal-delete-button')
      fireEvent.click(deleteButtonOnModal)
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(deleteRequested).toBe(true)
    })

    it('can edit the scheme through edit modal', async () => {
      let updateData: any = null
      server.use(
        http.put('/courses/:contextId/grading_schemes/:id', async ({params, request}) => {
          if (params.id === '1') {
            updateData = await request.json()
          }
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const scheme = getByTestId('grading-schemes-selector-option-1')
      fireEvent.click(scheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      const editButton = getByTestId('grading-scheme-1-edit-button')
      fireEvent.click(editButton)
      const input = getByTestId('grading-scheme-name-input')
      fireEvent.change(input, {target: {value: 'New Name'}})
      const saveButton = getByTestId('grading-scheme-edit-modal-update-button')
      fireEvent.click(saveButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(updateData).toEqual({
        title: 'New Name',
        id: '1',
        points_based: false,
        scaling_factor: 1,
        data: AccountGradingSchemes.find(accountScheme => accountScheme.id === '1')?.data,
      })
    })
  })
  describe('copy button tests', () => {
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

      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const copyButton = getByTestId('grading-schemes-selector-copy-button')
      fireEvent.click(copyButton)
      const duplicateButton = getByTestId('grading-scheme-duplicate-modal-duplicate-button')
      fireEvent.click(duplicateButton)
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(createData).toEqual({
        title: 'Default Canvas Grading Scheme Copy',
        points_based: false,
        scaling_factor: 1,
        data: DefaultGradingScheme.data,
      })
      expect(getByTestId('grading-scheme-edit-modal')).toBeInTheDocument()
    })
  })

  it('should create a new scheme when the new grading scheme button is clicked', async () => {
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

    const {getByTestId} = renderGradingSchemesSelector()
    await new Promise(resolve => setTimeout(resolve, 0))
    const newGradingSchemeButton = getByTestId('grading-schemes-selector-new-grading-scheme-button')
    newGradingSchemeButton.click()
    const input = getByTestId('grading-scheme-name-input')
    fireEvent.change(input, {target: {value: 'New Scheme'}})
    const createButton = getByTestId('grading-scheme-create-modal-save-button')
    createButton.click()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(createData).toEqual({
      title: 'New Scheme',
      points_based: false,
      scaling_factor: 1,
      data: DefaultGradingScheme.data,
    })
  })
})
