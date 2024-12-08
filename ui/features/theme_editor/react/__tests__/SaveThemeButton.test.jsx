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
import SaveThemeButton from '../SaveThemeButton'
import $ from 'jquery'

jest.mock('jquery', () => ({
  ajaxJSON: jest.fn(),
}))

describe('SaveThemeButton', () => {
  const defaultProps = {
    accountID: 'account123',
    brandConfigMd5: '00112233445566778899aabbccddeeff',
    sharedBrandConfigBeingEdited: {
      id: 321,
      name: 'Test Theme',
      account_id: '123',
      brand_config: {
        md5: '00112233445566778899aabbccddeeff',
        variables: {
          'some-var': '#123',
        },
      },
    },
    onSave: jest.fn(),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders a save button', () => {
    render(<SaveThemeButton {...defaultProps} />)
    expect(screen.getByRole('button', {name: 'Save theme'})).toBeInTheDocument()
  })

  it('shows modal when saving a new theme', async () => {
    const user = userEvent.setup()
    const propsWithoutSharedConfig = {
      ...defaultProps,
      sharedBrandConfigBeingEdited: {
        ...defaultProps.sharedBrandConfigBeingEdited,
        id: undefined,
      },
    }

    render(<SaveThemeButton {...propsWithoutSharedConfig} />)

    await user.click(screen.getByRole('button', {name: 'Save theme'}))

    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('saves existing theme without showing modal', async () => {
    const user = userEvent.setup()
    const updatedConfig = {brand_config: {some: 'data'}}
    $.ajaxJSON.mockImplementation((url, method, data, callback) => {
      callback(updatedConfig)
      return Promise.resolve(updatedConfig)
    })

    render(<SaveThemeButton {...defaultProps} />)

    await user.click(screen.getByRole('button', {name: 'Save theme'}))

    await waitFor(() => {
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
      expect(defaultProps.onSave).toHaveBeenCalledWith(updatedConfig)
      expect($.ajaxJSON).toHaveBeenCalledWith(
        expect.stringContaining(defaultProps.accountID),
        'PUT',
        expect.any(Object),
        expect.any(Function)
      )
    })
  })

  it('disables save button when preview is required', () => {
    render(<SaveThemeButton {...defaultProps} userNeedsToPreviewFirst={true} />)

    expect(screen.getByRole('button', {name: 'Save theme'})).toBeDisabled()
  })

  it('disables save button when there are no unsaved changes', () => {
    const propsWithSameMd5 = {
      ...defaultProps,
      sharedBrandConfigBeingEdited: {
        ...defaultProps.sharedBrandConfigBeingEdited,
        brand_config_md5: defaultProps.brandConfigMd5,
      },
    }

    render(<SaveThemeButton {...propsWithSameMd5} />)

    expect(screen.getByRole('button', {name: 'Save theme'})).toBeDisabled()
  })

  it('disables save button when using default config', () => {
    render(<SaveThemeButton {...defaultProps} brandConfigMd5={null} isDefaultConfig={true} />)

    expect(screen.getByRole('button', {name: 'Save theme'})).toBeDisabled()
  })

  it('saves new theme with name when provided', async () => {
    const user = userEvent.setup()
    const propsWithoutSharedConfig = {
      ...defaultProps,
      sharedBrandConfigBeingEdited: {
        ...defaultProps.sharedBrandConfigBeingEdited,
        id: undefined,
      },
    }
    const updatedConfig = {brand_config: {some: 'data'}}
    $.ajaxJSON.mockImplementation((url, method, data, callback) => {
      callback(updatedConfig)
      return Promise.resolve(updatedConfig)
    })

    render(<SaveThemeButton {...propsWithoutSharedConfig} />)

    await user.click(screen.getByRole('button', {name: 'Save theme'}))
    await user.type(screen.getByLabelText('Theme Name'), 'New Theme Name')

    const saveButton = await screen.findByRole('button', {name: 'Save theme'})
    await user.click(saveButton)

    await waitFor(() => {
      expect($.ajaxJSON).toHaveBeenCalledWith(
        expect.stringContaining(defaultProps.accountID),
        'POST',
        expect.any(Object),
        expect.any(Function)
      )
      expect(defaultProps.onSave).toHaveBeenCalledWith(updatedConfig)
    })
  })
})
