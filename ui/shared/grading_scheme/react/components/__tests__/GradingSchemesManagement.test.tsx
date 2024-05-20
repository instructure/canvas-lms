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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {fireEvent, render} from '@testing-library/react'
import {
  GradingSchemesManagement,
  type GradingSchemesManagementProps,
} from '../GradingSchemesManagement'
import {AccountGradingSchemes, DefaultGradingScheme} from './fixtures'

jest.mock('@canvas/do-fetch-api-effect')

describe('Grading Schemes Management Tests', () => {
  beforeEach(() => {
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: AccountGradingSchemes})
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: DefaultGradingScheme})
  })

  afterEach(() => {
    doFetchApi.mockClear()
  })

  const renderGradingSchemesManagement = (props: Partial<GradingSchemesManagementProps> = {}) => {
    return render(
      <GradingSchemesManagement
        contextId="1"
        contextType="Course"
        archivedGradingSchemesEnabled={false}
        onGradingSchemesChanged={() => {}}
        {...props}
      />
    )
  }

  it('should render grading schemes', async () => {
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(doFetchApi).toHaveBeenCalledTimes(2)
    expect(getByTestId('grading_scheme_1_edit_button')).toBeInTheDocument()
    expect(getByTestId('grading_scheme_2_edit_button')).toBeInTheDocument()
    expect(getByTestId('grading_scheme_3_edit_button')).toBeInTheDocument()
    expect(getByTestId('default_canvas_grading_scheme')).toBeInTheDocument()
  })

  it('should disable Account grading schemes when contextType is Course', async () => {
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    const course1EditButton = getByTestId('grading_scheme_1_edit_button')
    const course1DeleteButton = getByTestId('grading_scheme_1_delete_button')
    const account1EditButton = getByTestId('grading_scheme_2_edit_button')
    const account1DeleteButton = getByTestId('grading_scheme_2_delete_button')
    const course2EditButton = getByTestId('grading_scheme_3_edit_button')
    const course2DeleteButton = getByTestId('grading_scheme_3_delete_button')

    expect(course1EditButton).not.toBeDisabled()
    expect(course1DeleteButton).not.toBeDisabled()
    expect(course2EditButton).not.toBeDisabled()
    expect(course2DeleteButton).not.toBeDisabled()
    expect(account1EditButton).toBeDisabled()
    expect(account1DeleteButton).toBeDisabled()
  })

  it('should not disable Account grading schemes when contextType is Account', async () => {
    const {getByTestId} = renderGradingSchemesManagement({contextType: 'Account'})

    await new Promise(resolve => setTimeout(resolve, 0))
    const course1EditButton = getByTestId('grading_scheme_1_edit_button')
    const course1DeleteButton = getByTestId('grading_scheme_1_delete_button')
    const account1EditButton = getByTestId('grading_scheme_2_edit_button')
    const account1DeleteButton = getByTestId('grading_scheme_2_delete_button')
    const course2EditButton = getByTestId('grading_scheme_3_edit_button')
    const course2DeleteButton = getByTestId('grading_scheme_3_delete_button')

    expect(course1EditButton).not.toBeDisabled()
    expect(course1DeleteButton).not.toBeDisabled()
    expect(course2EditButton).not.toBeDisabled()
    expect(course2DeleteButton).not.toBeDisabled()
    expect(account1EditButton).not.toBeDisabled()
    expect(account1DeleteButton).not.toBeDisabled()
  })

  describe('archived grading schemes', () => {
    const renderArchivedGradingSchemesManagement = (
      props: Partial<GradingSchemesManagementProps> = {}
    ) => {
      return renderGradingSchemesManagement({archivedGradingSchemesEnabled: true, ...props})
    }

    it('should render three grading scheme tables, (default, active, archived)', async () => {
      const {getByTestId} = renderArchivedGradingSchemesManagement()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('grading-scheme-table-archived')).toBeInTheDocument()
      expect(getByTestId('grading-scheme-table-active')).toBeInTheDocument()
      expect(getByTestId('grading-scheme-table-default')).toBeInTheDocument()
    })

    describe('filtering', () => {
      it('should filter grading schemes by title', async () => {
        const {getByTestId, queryByTestId} = renderArchivedGradingSchemesManagement()
        await new Promise(resolve => setTimeout(resolve, 0))
        const input = getByTestId('grading-scheme-search')
        fireEvent.change(input, {target: {value: 'Grading Scheme 1'}})
        AccountGradingSchemes.forEach(scheme => {
          if (scheme.title === 'Grading Scheme 1') {
            expect(getByTestId(`grading-scheme-row-${scheme.id}`)).toBeInTheDocument()
          } else {
            expect(queryByTestId(`grading-scheme-row-${scheme.id}`)).not.toBeInTheDocument()
          }
        })
        expect(queryByTestId(`grading-scheme-row-`)).toBeInTheDocument()
      })

      it('shows archived and active schemes that match the filter', async () => {
        const {getByTestId, queryByTestId} = renderArchivedGradingSchemesManagement()
        await new Promise(resolve => setTimeout(resolve, 0))
        const input = getByTestId('grading-scheme-search')
        fireEvent.change(input, {target: {value: 'Grading Scheme'}})
        AccountGradingSchemes.forEach(scheme => {
          if (scheme.title.includes('Grading Scheme')) {
            expect(getByTestId(`grading-scheme-row-${scheme.id}`)).toBeInTheDocument()
          } else {
            expect(queryByTestId(`grading-scheme-row-${scheme.id}`)).not.toBeInTheDocument()
          }
        })
        expect(queryByTestId(`grading-scheme-row-`)).toBeInTheDocument()
      })

      it('always shows the default grading scheme', async () => {
        const {getByTestId} = renderArchivedGradingSchemesManagement()
        await new Promise(resolve => setTimeout(resolve, 0))
        const input = getByTestId('grading-scheme-search')
        fireEvent.change(input, {target: {value: 'Carrot Potato Scheme'}})
        expect(getByTestId('grading-scheme-row-')).toBeInTheDocument()
      })
    })
  })
})
