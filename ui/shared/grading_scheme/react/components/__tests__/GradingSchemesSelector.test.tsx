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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AccountGradingSchemes, DefaultGradingScheme, GradingSchemeSummaries} from './fixtures'
import {GradingSchemesSelector, type GradingSchemesSelectorProps} from '../GradingSchemesSelector'
import type {GradingScheme} from '@canvas/grading_scheme/gradingSchemeApiModel'

jest.mock('@canvas/do-fetch-api-effect')

function renderGradingSchemesSelector(props: Partial<GradingSchemesSelectorProps> = {}) {
  const onChange = jest.fn()

  const utils = render(
    <GradingSchemesSelector
      canManage={true}
      contextType="Course"
      contextId="1"
      archivedGradingSchemesEnabled={true}
      onChange={onChange}
      {...props}
    />
  )

  return {
    ...utils,
    onChange,
  }
}

describe('GradingSchemesSelector', () => {
  beforeEach(() => {
    doFetchApi.mockImplementation(
      (opts: {path: string; method: string; body: Record<any, any>}) => {
        switch (opts.path) {
          case '/courses/1/grading_scheme_summaries':
            return Promise.resolve({response: {ok: true}, json: GradingSchemeSummaries})
          case '/courses/1/grading_schemes/default':
            return Promise.resolve({response: {ok: true}, json: DefaultGradingScheme})
          case '/courses/1/grading_schemes': {
            const newScheme: Partial<GradingScheme> = {
              ...opts.body,
              id: '1000',
              context_id: '1',
              context_type: 'Course',
              assessed_assignment: false,
              permissions: {manage: true},
              context_name: 'Test Course',
              workflow_state: 'active',
            }
            return Promise.resolve({response: {ok: true}, json: newScheme})
          }
          default: {
            const id = opts.path.match(/\/courses\/1\/grading_schemes\/(\d+)/)?.[1]
            if (id) {
              const matchedScheme = AccountGradingSchemes.find(scheme => scheme.id === id)
              if (matchedScheme) return Promise.resolve({response: {ok: true}, json: matchedScheme})
            }
            return Promise.resolve({response: {ok: false}})
          }
        }
      }
    )
  })

  afterEach(() => {
    doFetchApi.mockClear()
  })
  it('should render a dropdown and view, copy, and new grading scheme buttons, and loads default scheme and scheme summaries', async () => {
    const {getByTestId} = renderGradingSchemesSelector()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(doFetchApi).toHaveBeenCalledTimes(2)
    expect(getByTestId('grading-schemes-selector-view-button')).toBeInTheDocument()
    expect(getByTestId('grading-schemes-selector-copy-button')).toBeInTheDocument()
    expect(getByTestId('grading-schemes-selector-new-grading-scheme-button')).toBeInTheDocument()
  })

  describe('view button tests', () => {
    it('should make an api call when the view button is clicked on a scheme other than the default one', async () => {
      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const scheme = getByTestId('grading-schemes-selector-option-1')
      fireEvent.click(scheme)
      const viewButton = getByTestId('grading-schemes-selector-view-button')
      fireEvent.click(viewButton)
      expect(doFetchApi).toHaveBeenCalledWith({path: '/courses/1/grading_schemes/1', method: 'GET'})
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
      expect(doFetchApi).toHaveBeenCalledTimes(2)
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
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/courses/1/grading_schemes/1',
        method: 'DELETE',
      })
    })

    it('can edit the scheme through edit modal', async () => {
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
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/courses/1/grading_schemes/1',
        method: 'PUT',
        body: {
          title: 'New Name',
          id: '1',
          points_based: false,
          scaling_factor: 1,
          data: AccountGradingSchemes.find(accountScheme => accountScheme.id === '1')?.data,
        },
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
      const {getByTestId} = renderGradingSchemesSelector()
      await new Promise(resolve => setTimeout(resolve, 0))
      const dropdown = getByTestId('grading-schemes-selector-dropdown')
      fireEvent.click(dropdown)
      const copyButton = getByTestId('grading-schemes-selector-copy-button')
      fireEvent.click(copyButton)
      const duplicateButton = getByTestId('grading-scheme-duplicate-modal-duplicate-button')
      fireEvent.click(duplicateButton)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/courses/1/grading_schemes',
        method: 'POST',
        body: {
          title: 'Default Canvas Grading Scheme Copy',
          points_based: false,
          scaling_factor: 1,
          data: DefaultGradingScheme.data,
        },
      })
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('grading-scheme-edit-modal')).toBeInTheDocument()
    })
  })

  it('should create a new scheme when the new grading scheme button is clicked', async () => {
    const {getByTestId} = renderGradingSchemesSelector()
    await new Promise(resolve => setTimeout(resolve, 0))
    const newGradingSchemeButton = getByTestId('grading-schemes-selector-new-grading-scheme-button')
    newGradingSchemeButton.click()
    const input = getByTestId('grading-scheme-name-input')
    fireEvent.change(input, {target: {value: 'New Scheme'}})
    const createButton = getByTestId('grading-scheme-create-modal-save-button')
    createButton.click()
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/courses/1/grading_schemes',
      method: 'POST',
      body: {
        title: 'New Scheme',
        points_based: false,
        scaling_factor: 1,
        data: DefaultGradingScheme.data,
      },
    })
  })
})
