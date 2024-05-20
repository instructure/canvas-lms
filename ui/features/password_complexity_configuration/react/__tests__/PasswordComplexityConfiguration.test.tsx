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
import {fireEvent, render} from '@testing-library/react'
import PasswordComplexityConfiguration from '../PasswordComplexityConfiguration'

describe('PasswordComplexityConfiguration', () => {
  it('opens the Tray when "View Options" button is clicked', () => {
    const {getByText} = render(<PasswordComplexityConfiguration />)
    fireEvent.click(getByText('View Options'))
    expect(getByText('Current Password Configuration')).toBeInTheDocument()
  })

  it('toggles all checkboxes with defaults set', async () => {
    const {getByText, findByTestId} = render(<PasswordComplexityConfiguration />)
    fireEvent.click(getByText('View Options'))

    let checkbox = await findByTestId('minimumCharacterLengthCheckbox')
    fireEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()

    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    checkbox = await findByTestId('requireNumbersCheckbox')
    fireEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()

    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    checkbox = await findByTestId('requireSymbolsCheckbox')
    fireEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()

    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    checkbox = await findByTestId('customForbiddenWordsCheckbox')
    fireEvent.click(checkbox)
    expect(checkbox).toBeChecked()

    fireEvent.click(checkbox)
    expect(checkbox).not.toBeChecked()
  })

  it('toggle input fields when checkbox is checked', async () => {
    const {getByText, findByTestId} = render(<PasswordComplexityConfiguration />)
    fireEvent.click(getByText('View Options'))

    let checkbox = await findByTestId('minimumCharacterLengthCheckbox')
    let input = await findByTestId('minimumCharacterLengthInput')
    expect(input).toBeEnabled()

    checkbox = await findByTestId('customMaxLoginAttemptsCheckbox')
    fireEvent.click(checkbox)
    input = await findByTestId('customMaxLoginAttemptsInput')
    expect(input).toBeEnabled()
  })

  it('opens the file upload modal when "Upload" button is clicked', async () => {
    const {getByText, findByTestId} = render(<PasswordComplexityConfiguration />)
    fireEvent.click(getByText('View Options'))
    const checkbox = await findByTestId('customForbiddenWordsCheckbox')
    fireEvent.click(checkbox)
    fireEvent.click(getByText('Upload'))
    expect(getByText('Upload Forbidden Words/Terms List')).toBeInTheDocument()
  })

  it('closes the Tray when "Cancel" button is clicked', async () => {
    const {getByText, queryByText, findByTestId} = render(<PasswordComplexityConfiguration />)
    fireEvent.click(getByText('View Options'))
    const cancelButton = await findByTestId('cancelButton')
    fireEvent.click(cancelButton)
    expect(queryByText('Password Options Tray')).not.toBeInTheDocument()
  })
})
