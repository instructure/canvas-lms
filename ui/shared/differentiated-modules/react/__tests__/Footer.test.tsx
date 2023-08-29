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
import Footer, {FooterProps} from '../Footer'

describe('Footer', () => {
  const props: FooterProps = {
    onDismiss: jest.fn(),
    onUpdate: jest.fn(),
  }

  const renderComponent = (overrides = {}) => render(<Footer {...props} {...overrides} />)

  beforeEach(() => {
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Cancel')).toBeInTheDocument()
    expect(getByText('Update Module')).toBeInTheDocument()
  })

  it('calls onDismiss when cancel button is clicked', () => {
    const {getByRole} = renderComponent()
    getByRole('button', {name: /cancel/i}).click()
    expect(props.onDismiss).toHaveBeenCalled()
  })

  it('calls onUpdate and onDismiss when update button is clicked', () => {
    const {getByRole} = renderComponent()
    getByRole('button', {name: /update module/i}).click()
    expect(props.onUpdate).toHaveBeenCalled()
    expect(props.onDismiss).toHaveBeenCalled()
  })
})
