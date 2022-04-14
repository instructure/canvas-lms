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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Footer} from '../Footer'

describe('<Footer />', () => {
  let defaults

  beforeEach(() => {
    defaults = {
      onCancel: jest.fn(),
      onSubmit: jest.fn(),
      onReplace: jest.fn(),
      editing: false
    }
  })

  afterEach(() => jest.clearAllMocks())

  it('submits the icon maker tray', () => {
    const onSubmit = jest.fn()
    render(<Footer {...defaults} onSubmit={onSubmit} />)
    userEvent.click(screen.getByRole('button', {name: /apply/i}))
    expect(onSubmit).toHaveBeenCalled()
  })

  it('closes the icon maker tray', () => {
    const onCancel = jest.fn()
    render(<Footer {...defaults} onCancel={onCancel} />)
    userEvent.click(screen.getByRole('button', {name: /cancel/i}))
    expect(onCancel).toHaveBeenCalled()
  })

  it('renders the footer disabled', () => {
    render(<Footer {...defaults} disabled />)
    const cancelButton = screen.getByRole('button', {name: /cancel/i})
    const applyButton = screen.getByRole('button', {name: /apply/i})
    expect(cancelButton).toBeDisabled()
    expect(applyButton).toBeDisabled()
  })

  describe('when editing', () => {
    beforeEach(() => {
      defaults.editing = true
    })

    const subject = (overrides = {}) => render(<Footer {...defaults} {...overrides} />)

    it('renders the "apply to all" checkbox', async () => {
      const {findByTestId} = subject()
      expect(await findByTestId('cb-replace-all')).toBeInTheDocument()
    })

    it('renders the "save" button', async () => {
      const {findByText} = subject()
      expect(await findByText('Save')).toBeInTheDocument()
    })

    it('does not render the "apply" button', async () => {
      const {queryByText} = subject()
      expect(await queryByText('Apply')).not.toBeInTheDocument()
    })

    it('calls "onSubmit" when "Save" is pressed"', async () => {
      const {findByText} = subject()
      userEvent.click(await findByText('Save'))
      expect(defaults.onSubmit).toHaveBeenCalled()
    })
  })
})
