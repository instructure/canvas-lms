/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import IntegrationRow from '../IntegrationRow'

describe('IntegrationRow', () => {
  const onChange = jest.fn()
  const props = overrides => ({
    name: 'Microsoft Sync',
    enabled: true,
    loading: false,
    onChange,
    ...overrides
  })
  const subject = overrides => render(<IntegrationRow {...props(overrides)} />)

  it('displays the integration name', () => {
    expect(subject().getAllByText('Microsoft Sync')).not.toHaveLength(0)
  })

  it('shows the integration is enabled', () => {
    expect(subject().getByLabelText('Toggle Microsoft Sync').checked).toBeTruthy()
  })

  it('calls "onChange" when toggled', () => {
    fireEvent.click(subject().getByLabelText('Toggle Microsoft Sync'))
    expect(onChange).toHaveBeenCalled()
  })

  describe('when "enabled" is false', () => {
    const propOverrides = {enabled: false}

    it('shows the integration is not enabled', () => {
      expect(subject(propOverrides).getByLabelText('Toggle Microsoft Sync').checked).toBeFalsy()
    })
  })

  describe('when "loading" is true', () => {
    const propOverrides = {loading: true}

    it('shows the loading spinner', () => {
      expect(subject(propOverrides).getByText('Loading Microsoft Sync data')).toBeInTheDocument()
    })
  })

  describe('when "error" is set', () => {
    const propOverrides = {error: 'Something bad happened!', expanded: true}

    it('shows the error', () => {
      const expectedError = `An error occurred, please try again. Error: ${propOverrides.error}`

      expect(subject(propOverrides).getByText(expectedError)).toBeInTheDocument()
    })
  })
})
