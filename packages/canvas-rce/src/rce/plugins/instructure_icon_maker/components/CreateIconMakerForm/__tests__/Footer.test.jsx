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
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Footer} from '../Footer'

describe('<Footer />', () => {
  let defaults

  beforeEach(() => {
    defaults = {
      onCancel: jest.fn(),
      onSubmit: jest.fn(),
      onReplace: jest.fn(),
      editing: false,
      isModified: false,
      replaceAll: false,
      disabled: false,
    }
  })

  const subject = (overrides = {}) => render(<Footer {...defaults} {...overrides} />)

  afterEach(() => jest.clearAllMocks())

  it('calls "onSubmit" when pressing create button', async () => {
    const {getByTestId} = subject()
    await userEvent.click(getByTestId('create-icon-button'))
    expect(defaults.onSubmit).toHaveBeenCalled()
  })

  it('calls "onCancel" when pressing cancel button', async () => {
    const {getByTestId} = subject()
    await userEvent.click(getByTestId('icon-maker-cancel'))
    expect(defaults.onCancel).toHaveBeenCalled()
  })

  it('disabled prop disables apply and cancel buttons', () => {
    const {getByTestId} = subject({disabled: true})
    const cancelButton = getByTestId('icon-maker-cancel')
    const applyButton = getByTestId('create-icon-button')
    expect(cancelButton).toBeDisabled()
    expect(applyButton).toBeDisabled()
  })

  describe('when editing', () => {
    beforeEach(() => {
      defaults.editing = true
    })

    it('renders the "apply to all" checkbox', async () => {
      const {findByTestId} = subject()
      expect(await findByTestId('cb-replace-all')).toBeInTheDocument()
    })

    it('renders the "save" button with "save copy" text by default', async () => {
      const {findByText} = subject()
      expect(await findByText('Save Copy')).toBeInTheDocument()
    })

    it('renders the "save" button with "save" text when replacing all', async () => {
      const {findByText} = subject({replaceAll: true})
      expect(await findByText('Save')).toBeInTheDocument()
    })

    it('does not render the "apply" button', () => {
      const {queryByTestId} = subject()
      expect(queryByTestId('create-icon-button')).not.toBeInTheDocument()
    })

    it('Disable the "save" button when the user has not made changes', async () => {
      const {findByTestId} = subject()
      const saveButton = await findByTestId('icon-maker-save')
      expect(saveButton.closest('button')).toBeDisabled()
    })

    it('renders Tooltip when hover the "save" button', async () => {
      const {findByTestId, findByText} = subject()
      const saveButton = await findByTestId('icon-maker-save')
      fireEvent.mouseOver(saveButton)
      expect(await findByText('No changes to save.')).toBeInTheDocument()
    })

    it('Enable the "save" button when the user has made changes', async () => {
      const {findByTestId} = subject({isModified: true})
      const saveButton = await findByTestId('icon-maker-save')
      expect(saveButton.closest('button')).not.toBeDisabled()
    })

    it('calls "onSubmit" when "Save" is pressed"', async () => {
      const {findByTestId} = subject({isModified: true})
      await userEvent.click(await findByTestId('icon-maker-save'))
      expect(defaults.onSubmit).toHaveBeenCalled()
    })
  })
})
