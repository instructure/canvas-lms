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
import {render} from '@testing-library/react'
import {
  GradingSchemeViewEditModal,
  type GradingSchemeViewEditModalProps,
} from '../GradingSchemeViewEditModal'
import {AccountGradingSchemes, DefaultGradingScheme} from './fixtures'

jest.mock('@canvas/do-fetch-api-effect')

describe('Grading Schemes View Edit Tests', () => {
  beforeEach(() => {
    doFetchApi.mockClear()
  })

  afterEach(() => {
    doFetchApi.mockClear()
  })

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
      />
    )
  }

  it('should render selected grading scheme', async () => {
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: AccountGradingSchemes[0]})
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: DefaultGradingScheme})
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(doFetchApi).toHaveBeenCalledTimes(2)
    expect(getByTestId('grading_scheme_1_edit_button')).toBeInTheDocument()
  })

  it('should not disable course grading scheme buttons', async () => {
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: AccountGradingSchemes[0]})
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: DefaultGradingScheme})
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(doFetchApi).toHaveBeenCalledTimes(2)
    expect(getByTestId('grading_scheme_1_edit_button')).not.toBeDisabled()
  })

  it('should disable Account grading scheme buttons when contextType is Course', async () => {
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: AccountGradingSchemes[1]})
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: DefaultGradingScheme})
    const {getByTestId} = renderGradingSchemesManagement()

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(doFetchApi).toHaveBeenCalledTimes(2)
    expect(getByTestId('grading_scheme_2_edit_button')).toBeDisabled()
  })

  it('should not disable Account grading scheme buttons when contextType is Account', async () => {
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: AccountGradingSchemes[1]})
    doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: DefaultGradingScheme})
    const {getByTestId} = renderGradingSchemesManagement({contextType: 'Account'})

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(doFetchApi).toHaveBeenCalledTimes(2)
    expect(getByTestId('grading_scheme_2_edit_button')).not.toBeDisabled()
  })
})
