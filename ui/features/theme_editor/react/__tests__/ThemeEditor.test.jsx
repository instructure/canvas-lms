/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import ThemeEditor from '../ThemeEditor'

describe('ThemeEditor', () => {
  beforeEach(() => {
    Object.defineProperty(window, 'sessionStorage', {
      value: {
        getItem: jest.fn(() => null),
        setItem: jest.fn(),
        removeItem: jest.fn(),
      },
      writable: true,
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  const defaultProps = {
    accountID: '1',
    brandConfig: {
      md5: '9e3c6d00c73e0fa989896e63077b45a8',
      variables: {
        'ic-brand-primary': '#2B7ABC',
        'ic-brand-font-color-dark': '#273540',
      },
    },
    sharedBrandConfigs: [],
    sharedBrandConfigBeingEdited: {
      id: '1',
      brand_config_md5: '9e3c6d00c73e0fa989896e63077b45a8',
      name: 'Test Theme',
    },
    allowGlobalIncludes: true,
    hasUnsavedChanges: false,
    variableSchema: [
      {
        group_name: 'Global Branding',
        group_key: 'global_branding',
        variables: [
          {
            variable_name: 'ic-brand-primary',
            type: 'color',
            human_name: 'Primary Brand Color',
            default: '#2B7ABC',
          },
          {
            variable_name: 'ic-brand-font-color-dark',
            type: 'color',
            human_name: 'Main Text Color',
            default: '#273540',
          },
        ],
      },
    ],
  }

  it('makes preview iframe inaccessible when there are unsaved changes', async () => {
    const user = userEvent.setup()
    const {getByTitle, getByLabelText} = render(<ThemeEditor {...defaultProps} />)
    const iframe = getByTitle('Preview')
    const colorInput = getByLabelText('Primary Brand Color')

    expect(iframe).toHaveAttribute('aria-hidden', 'false')
    await user.clear(colorInput)
    await user.type(colorInput, '#000000')
    expect(iframe).toHaveAttribute('aria-hidden', 'true')
  })

  it('initializes theme store with correct values', () => {
    const {getByRole} = render(<ThemeEditor {...defaultProps} />)
    const colorInput = getByRole('textbox', {name: /Primary Brand Color/i})
    expect(colorInput.placeholder).toBe('#2B7ABC')
  })

  it('updates theme store when color value changes', async () => {
    const {getByRole} = render(<ThemeEditor {...defaultProps} />)
    const user = userEvent.setup()
    const colorInput = getByRole('textbox', {name: /Primary Brand Color/i})

    await user.clear(colorInput)
    await user.type(colorInput, '#000000')
    expect(colorInput.value).toBe('#000000')
  })

  it('updates theme store when file is uploaded', async () => {
    const {container, getByRole} = render(<ThemeEditor {...defaultProps} />)
    const user = userEvent.setup()
    const uploadTab = getByRole('tab', {name: /Upload/i})
    await user.click(uploadTab)

    // Mock URL.createObjectURL since it's not available in jsdom
    const mockObjectURL = 'blob:mock-url'
    const originalCreateObjectURL = window.URL.createObjectURL
    window.URL.createObjectURL = jest.fn(() => mockObjectURL)

    const fileInput = container.querySelector('input[type="file"][accept=".css"]')
    const file = new File(['test'], 'theme.css', {type: 'text/css'})

    await user.upload(fileInput, file)
    expect(fileInput.files[0]).toBe(file)
    expect(window.URL.createObjectURL).toHaveBeenCalledWith(file)

    // Cleanup
    window.URL.createObjectURL = originalCreateObjectURL
  })

  it('resets value to original when reset is clicked', async () => {
    const {getByRole} = render(<ThemeEditor {...defaultProps} />)
    const user = userEvent.setup()
    const colorInput = getByRole('textbox', {name: /Primary Brand Color/i})

    await user.clear(colorInput)
    await user.type(colorInput, '#000000')
    expect(colorInput.value).toBe('#000000')

    await user.clear(colorInput)
    expect(colorInput.value).toBe('')
    expect(colorInput.placeholder).toBe('#2B7ABC')
  })
})
