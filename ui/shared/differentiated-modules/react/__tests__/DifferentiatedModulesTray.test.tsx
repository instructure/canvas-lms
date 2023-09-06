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
  DifferentiatedModulesTrayProps,
} from '../DifferentiatedModulesTray'

describe('DifferentiatedModulesTray', () => {
  const props: DifferentiatedModulesTrayProps = {
    open: true,
    onDismiss: () => {},
    moduleElement: document.createElement('div'),
    initialTab: 'assign-to',
    assignOnly: true,
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

  it('does not render tabs when assignOnly is true', () => {
    const {queryByTestId} = renderComponent()
    expect(queryByTestId('assign-to-panel')).not.toBeInTheDocument()
    expect(queryByTestId('settings-panel')).not.toBeInTheDocument()
  })

  it('renders tabs when assignOnly is false', () => {
    const {getByTestId} = renderComponent({assignOnly: false})
    expect(getByTestId('assign-to-panel')).toBeInTheDocument()
    expect(getByTestId('settings-panel')).toBeInTheDocument()
  })

  it('always opens to the initialTab', async () => {
    const {getByRole, rerender} = renderComponent({assignOnly: false})
    expect(getByRole('tab', {name: /Assign To/})).toHaveAttribute('aria-selected', 'true')
    getByRole('tab', {name: /Settings/}).click()
    await waitFor(() => {
      expect(getByRole('tab', {name: /Settings/})).toHaveAttribute('aria-selected', 'true')
    })
    rerender(<DifferentiatedModulesTray {...props} open={false} assignOnly={false} />)
    rerender(<DifferentiatedModulesTray {...props} assignOnly={false} />)
    expect(getByRole('tab', {name: /Assign To/})).toHaveAttribute('aria-selected', 'true')
  })
})
