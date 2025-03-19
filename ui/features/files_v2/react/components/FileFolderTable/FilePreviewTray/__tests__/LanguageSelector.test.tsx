/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {LanguageSelector, LanguageSelectorProps} from '../LanguageSelector'
import userEvent from '@testing-library/user-event'

jest.mock('@instructure/canvas-media', () => ({
  closedCaptionLanguages: [
    {id: 'aa', label: 'Afar'},
    {id: 'en', label: 'English'},
    {id: 'es', label: 'Spanish'},
  ],
}))

const defaultProps: LanguageSelectorProps = {
  locale: '',
  handleLocaleChange: jest.fn(),
  localeError: '',
}

const renderComponent = (props?: Partial<LanguageSelectorProps>) => {
  return render(<LanguageSelector {...defaultProps} {...props} />)
}

describe('LanguageSelector', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('updates input and calls handleLocaleChange when an option is selected', async () => {
    renderComponent()

    const input = screen.getByPlaceholderText(/start typing to search/i) as HTMLInputElement
    await userEvent.type(input, 'en')

    const option = await waitFor(() => screen.getByText(/English/i))
    await userEvent.click(option)

    expect(defaultProps.handleLocaleChange).toHaveBeenCalledWith('en')
  })

  it('does not show languages that are already present', async () => {
    renderComponent({existingLocales: ['es']})
    const input = screen.getByPlaceholderText(/start typing to search/i)
    await userEvent.click(input)

    expect(screen.queryByText(/Spanish/i)).not.toBeInTheDocument()
    expect(screen.getByText(/English/i)).toBeInTheDocument()
  })

  it('displays error message when localeError is present', async () => {
    renderComponent({localeError: 'error message'})
    expect(screen.getByText(/error message/i)).toBeInTheDocument()
  })

  it('renders English as the first option', async () => {
    renderComponent()
    const input = screen.getByPlaceholderText(/start typing to search/i)
    await userEvent.click(input)

    const options = screen.getAllByRole('option')
    expect(options[0]).toHaveTextContent(/English/i)
  })
})
