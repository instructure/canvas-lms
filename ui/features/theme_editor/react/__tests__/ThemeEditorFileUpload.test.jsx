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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ThemeEditorFileUpload from '../ThemeEditorFileUpload'

describe('ThemeEditorFileUpload', () => {
  const mockCreateObjectURL = jest.fn()
  const originalURL = window.URL

  beforeAll(() => {
    // @ts-expect-error
    window.URL = {
      ...originalURL,
      createObjectURL: mockCreateObjectURL,
    }
  })

  afterAll(() => {
    window.URL = originalURL
  })

  beforeEach(() => {
    mockCreateObjectURL.mockReset()
    mockCreateObjectURL.mockReturnValue('blob:test-url')
  })

  const renderComponent = (props = {}) => {
    const defaultProps = {
      onChange: jest.fn(),
      handleThemeStateChange: jest.fn(),
      name: 'test-upload',
    }
    return render(<ThemeEditorFileUpload {...defaultProps} {...props} />)
  }

  it('renders button disabled when nothing to reset', () => {
    renderComponent()
    const button = screen.getByRole('button', {name: /Reset/})
    expect(button).toBeDisabled()
  })

  it('renders button enabled when there is something to reset', () => {
    renderComponent({userInput: {val: 'foo'}})
    const button = screen.getByRole('button', {name: /Undo/})
    expect(button).toBeEnabled()
  })

  describe('button labels', () => {
    it('shows "Reset" by default', () => {
      renderComponent()
      expect(screen.getByRole('button', {name: /Reset/})).toBeInTheDocument()
    })

    it('shows "Clear" when there is a current value', () => {
      renderComponent({currentValue: 'foo'})
      expect(screen.getByRole('button', {name: /Clear/})).toBeInTheDocument()
    })

    it('shows "Undo" when there is user input', () => {
      renderComponent({userInput: {val: 'foo'}})
      expect(screen.getByRole('button', {name: /Undo/})).toBeInTheDocument()
    })
  })

  describe('reset functionality', () => {
    it('resets when user input has a value', async () => {
      const onChange = jest.fn()
      const handleThemeStateChange = jest.fn()
      renderComponent({userInput: {val: 'foo'}, onChange, handleThemeStateChange, name: 'test'})
      const button = screen.getByRole('button', {name: /Undo/})
      await userEvent.click(button)
      expect(onChange).toHaveBeenCalledWith(null)
      expect(handleThemeStateChange).toHaveBeenCalledWith('test', null, {
        customFileUpload: true,
        resetValue: true,
        useDefault: false,
      })
    })

    it('resets when user input is empty string', async () => {
      const onChange = jest.fn()
      const handleThemeStateChange = jest.fn()
      renderComponent({userInput: {val: ''}, onChange, handleThemeStateChange, name: 'test'})
      const button = screen.getByRole('button', {name: /Undo/})
      await userEvent.click(button)
      expect(onChange).toHaveBeenCalledWith(null)
      expect(handleThemeStateChange).toHaveBeenCalledWith('test', null, {
        customFileUpload: true,
        resetValue: true,
        useDefault: false,
      })
    })

    it('resets when there is a current value', async () => {
      const onChange = jest.fn()
      const handleThemeStateChange = jest.fn()
      renderComponent({currentValue: 'foo', onChange, handleThemeStateChange, name: 'test'})
      const button = screen.getByRole('button', {name: /Clear/})
      await userEvent.click(button)
      expect(onChange).toHaveBeenCalledWith('')
      expect(handleThemeStateChange).toHaveBeenCalledWith('test', null, {
        customFileUpload: true,
        resetValue: true,
        useDefault: true,
      })
    })
  })

  describe('file handling', () => {
    it('calls onChange with file data when file is selected', async () => {
      const onChange = jest.fn()
      const handleThemeStateChange = jest.fn()
      renderComponent({onChange, handleThemeStateChange, name: 'test'})
      const file = new File(['test'], 'test.jpg', {type: 'image/jpeg'})
      const input = screen.getByLabelText(/Select/i)
      await userEvent.upload(input, file)
      expect(handleThemeStateChange).toHaveBeenCalledWith('test', file, {customFileUpload: true})
      expect(onChange).toHaveBeenCalledWith('blob:test-url')
      expect(mockCreateObjectURL).toHaveBeenCalledWith(file)
    })
  })

  describe('display value', () => {
    it('shows empty input when no value', () => {
      renderComponent()
      const input = screen.getByLabelText(/Select/i)
      expect(
        input.parentElement.querySelector('.ThemeEditorFileUpload__fake-input'),
      ).toHaveTextContent('')
    })

    it('shows filename when file is selected', () => {
      renderComponent({userInput: {val: 'blob:test'}, currentValue: 'test.jpg'})
      const input = screen.getByLabelText(/Select/i)
      expect(
        input.parentElement.querySelector('.ThemeEditorFileUpload__fake-input'),
      ).toBeInTheDocument()
    })

    it('shows current value when no user input', () => {
      renderComponent({currentValue: 'current.jpg'})
      const input = screen.getByLabelText(/Select/i)
      expect(
        input.parentElement.querySelector('.ThemeEditorFileUpload__fake-input'),
      ).toHaveTextContent('current.jpg')
    })
  })
})
