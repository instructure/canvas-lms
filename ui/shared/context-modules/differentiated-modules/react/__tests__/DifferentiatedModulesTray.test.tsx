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
import {render, waitFor} from '@testing-library/react'
import DifferentiatedModulesTray, {
  type DifferentiatedModulesTrayProps,
} from '../DifferentiatedModulesTray'

describe('DifferentiatedModulesTray', () => {
  const props: DifferentiatedModulesTrayProps = {
    onDismiss: () => {},
    moduleElement: document.createElement('div'),
    moduleId: '1',
    initialTab: 'assign-to',
    courseId: '1',
  }

  const renderComponent = (overrides = {}) =>
    render(<DifferentiatedModulesTray {...props} {...overrides} />)

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Edit Module Settings')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    const onDismiss = jest.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: /close/i}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  it('renders tabs when moduleId is set', () => {
    const {getByTestId} = renderComponent({moduleId: '1'})
    expect(getByTestId('assign-to-panel')).toBeInTheDocument()
    expect(getByTestId('settings-panel')).toBeInTheDocument()
  })

  it('does not render tabs when moduleId is not set"', () => {
    const {queryByTestId} = renderComponent({moduleId: undefined})
    expect(queryByTestId('assign-to-panel')).not.toBeInTheDocument()
    expect(queryByTestId('settings-panel')).not.toBeInTheDocument()
  })

  it('opens to settings when initialTab is "settings"', async () => {
    const {getByRole} = renderComponent({initialTab: 'settings'})
    await waitFor(() =>
      expect(getByRole('tab', {name: /Settings/})).toHaveAttribute('aria-selected', 'true')
    )
  })

  describe('Module creation', () => {
    it('renders module creation variant when moduleId is not passed', async () => {
      const {getByTestId, getByRole, queryByText} = renderComponent({moduleId: undefined})
      expect(getByTestId('header-label').textContent).toBe('Add Module')
      expect(queryByText('Edit Module Settings')).not.toBeInTheDocument()
      expect(getByRole('button', {name: /Add Module/})).toBeInTheDocument()
    })

    it('does not render the "Assign To" tab', async () => {
      const {queryByRole} = renderComponent({moduleId: undefined})
      expect(queryByRole('tab', {name: /Assign To/})).not.toBeInTheDocument()
    })
  })
})
