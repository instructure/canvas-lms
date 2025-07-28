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
import {fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import SaveThemeButton, {SaveThemeButtonProps, SharedBrandConfig} from '../SaveThemeButton'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

describe('SaveThemeButton', () => {
  const defaultProps: SaveThemeButtonProps = {
    accountID: 'account123',
    brandConfigMd5: '00112233445566778899aabbccddeeff',
    sharedBrandConfigBeingEdited: {
      id: '123',
      name: 'Test Theme',
      account_id: '123',
      brand_config_md5: '00112233445566778899aabbccddeeff',
    },
    onSave: jest.fn(),
    isDefaultConfig: false,
    userNeedsToPreviewFirst: false,
  }

  const server = setupServer()

  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    jest.clearAllMocks()
    server.resetHandlers()
  })

  it('renders a save button', () => {
    render(<SaveThemeButton {...defaultProps} />)

    const button = screen.getByLabelText('Save theme')
    expect(button).toBeInTheDocument()
  })

  it('shows modal when saving a new theme', async () => {
    const propsWithoutSharedConfig: SaveThemeButtonProps = {
      ...defaultProps,
      sharedBrandConfigBeingEdited: undefined,
    }
    render(<SaveThemeButton {...propsWithoutSharedConfig} />)
    const button = screen.getByLabelText('Save theme')

    await userEvent.click(button)

    const dialog = await screen.findByLabelText('Save Theme Dialog')
    expect(dialog).toBeInTheDocument()
  })

  it('saves existing theme without showing modal', async () => {
    const responseData: SharedBrandConfig = {
      ...(defaultProps.sharedBrandConfigBeingEdited as SharedBrandConfig),
      brand_config_md5: 'new_md5',
    }
    const url = `/api/v1/accounts/${defaultProps.accountID}/shared_brand_configs/${defaultProps.sharedBrandConfigBeingEdited?.id}`
    server.use(
      http.put(url, async ({request}) => {
        const body = await request.json()
        expect(body).toEqual({shared_brand_config: {brand_config_md5: defaultProps.brandConfigMd5}})
        return HttpResponse.json(responseData)
      }),
    )
    render(
      <SaveThemeButton {...{...defaultProps, sharedBrandConfigBeingEdited: {...responseData}}} />,
    )
    const button = screen.getByLabelText('Save theme')

    await userEvent.click(button)

    await waitFor(() => {
      expect(defaultProps.onSave).toHaveBeenCalledWith(responseData)
      const dialog = screen.queryByLabelText('Save Theme Dialog')
      expect(dialog).not.toBeInTheDocument()
    })
  })

  it('disables save button when preview is required', () => {
    render(<SaveThemeButton {...defaultProps} userNeedsToPreviewFirst={true} />)

    const button = screen.getByLabelText('Save theme')
    expect(button).toBeDisabled()
  })

  it('disables save button when there are no unsaved changes', () => {
    const propsWithSameMd5: SaveThemeButtonProps = {
      ...defaultProps,
      sharedBrandConfigBeingEdited: {
        ...defaultProps.sharedBrandConfigBeingEdited,
        brand_config_md5: defaultProps.brandConfigMd5,
      } as SharedBrandConfig,
    }

    render(<SaveThemeButton {...propsWithSameMd5} />)

    const button = screen.getByLabelText('Save theme')
    expect(button).toBeDisabled()
  })

  it('disables save button when using default config', () => {
    render(<SaveThemeButton {...defaultProps} brandConfigMd5={undefined} isDefaultConfig={true} />)

    const button = screen.getByLabelText('Save theme')
    expect(button).toBeDisabled()
  })

  it('saves new theme with name when provided', async () => {
    const propsWithoutSharedConfig: SaveThemeButtonProps = {
      ...defaultProps,
      sharedBrandConfigBeingEdited: undefined,
    }
    const responseData: SharedBrandConfig = {
      ...(defaultProps.sharedBrandConfigBeingEdited as SharedBrandConfig),
      brand_config_md5: 'new_md5',
    }
    const url = `/api/v1/accounts/${defaultProps.accountID}/shared_brand_configs`
    server.use(
      http.post(url, async ({request}) => {
        const body = await request.json()
        expect(body).toEqual({
          shared_brand_config: {
            brand_config_md5: defaultProps.brandConfigMd5,
            name: newThemeName,
          },
        })
        return HttpResponse.json(responseData)
      }),
    )
    render(<SaveThemeButton {...propsWithoutSharedConfig} />)
    const saveButton = screen.getByLabelText('Save theme')
    const newThemeName = 'New Theme Name'

    await userEvent.click(saveButton)
    const dialog = screen.getByLabelText('Save Theme Dialog')
    const themeName = within(dialog).getByPlaceholderText('Pick a name to save this theme as')
    fireEvent.input(themeName, {target: {value: newThemeName}})
    const modalSaveButton = await within(dialog).findByLabelText('Save theme')
    await userEvent.click(modalSaveButton)

    await waitFor(() => {
      expect(defaultProps.onSave).toHaveBeenCalledWith(responseData)
      const dialog = screen.queryByLabelText('Save Theme Dialog')
      expect(dialog).not.toBeInTheDocument()
    })
  })
})
