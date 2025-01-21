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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import RestrictedRadioButtons from '../RestrictedRadioButtons'
import Folder from '../../../backbone/models/Folder'

const renderComponent = (props = {}) => {
  const defaultProps = {
    models: [new Folder({id: 999})],
    radioStateChange: jest.fn(),
  }
  return render(<RestrictedRadioButtons {...defaultProps} {...props} />)
}

describe('RestrictedRadioButtons', () => {
  it('renders all radio button options', () => {
    renderComponent()

    expect(screen.getByLabelText('Publish')).toBeInTheDocument()
    expect(screen.getByLabelText('Unpublish')).toBeInTheDocument()
    expect(screen.getByLabelText('Only available with link')).toBeInTheDocument()
    expect(screen.getByLabelText('Schedule availability')).toBeInTheDocument()
  })

  describe('with multiple selected items', () => {
    it('has no options selected by default when items have different states', () => {
      const models = [new Folder({id: 1000, hidden: false}), new Folder({id: 999, hidden: true})]
      renderComponent({models})

      const radioButtons = screen.getAllByRole('radio')
      radioButtons.forEach(radio => {
        expect(radio).not.toBeChecked()
      })
    })
  })

  describe('radio button selection', () => {
    it('allows selecting publish option', async () => {
      const user = userEvent.setup()
      renderComponent()

      await user.click(screen.getByLabelText('Publish'))
      expect(screen.getByLabelText('Publish')).toBeChecked()
    })

    it('allows selecting unpublish option', async () => {
      const user = userEvent.setup()
      renderComponent()

      await user.click(screen.getByLabelText('Unpublish'))
      expect(screen.getByLabelText('Unpublish')).toBeChecked()
    })

    it('allows selecting link only option', async () => {
      const user = userEvent.setup()
      renderComponent()

      await user.click(screen.getByLabelText('Only available with link'))
      expect(screen.getByLabelText('Only available with link')).toBeChecked()
    })

    it('allows selecting schedule availability option', async () => {
      const user = userEvent.setup()
      renderComponent()

      await user.click(screen.getByLabelText('Schedule availability'))
      expect(screen.getByLabelText('Schedule availability')).toBeChecked()
    })
  })

  it('calls radioStateChange when an option is selected', async () => {
    const radioStateChange = jest.fn()
    const user = userEvent.setup()
    renderComponent({radioStateChange})

    const unpublishOption = screen.getByLabelText('Unpublish')
    await user.click(unpublishOption)
    await waitFor(() => {
      expect(unpublishOption).toBeChecked()
      expect(radioStateChange).toHaveBeenCalled()
    })
  })

  it('shows date fields when schedule availability is selected', async () => {
    const user = userEvent.setup()
    renderComponent()

    await user.click(screen.getByLabelText('Schedule availability'))

    // The date fields should be visible in the document
    expect(document.querySelector('.RestrictedRadioButtons__dates_wrapper')).not.toHaveClass(
      'RestrictedRadioButtons__dates_wrapper_hidden',
    )
  })
})
