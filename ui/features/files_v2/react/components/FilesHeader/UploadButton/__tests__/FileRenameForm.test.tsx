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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import FileRenameForm from '../FileRenameForm'

const textFile = new File(['foo'], 'foo.txt', {type: 'text/plain'})

const defaultProps = {
  open: true,
  onClose: jest.fn(),
  fileOptions: {
    name: 'foo.txt',
    file: textFile,
    cannotOverwrite: false,
    expandZip: false,
  },
  onNameConflictResolved: jest.fn(),
}
const renderComponent = (props = {}) => render(<FileRenameForm {...defaultProps} {...props} />)

describe('FileRenameForm', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders header', () => {
    renderComponent()
    expect(screen.getByText('Copy')).toBeInTheDocument()
  })

  describe('renders body', () => {
    it('when is not editing and can overwrite', () => {
      renderComponent()
      expect(
        screen.getByText(
          'A file named "foo.txt" already exists in this location. Do you want to replace the existing file?',
        ),
      ).toBeInTheDocument()
    })

    it('when is editing', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('rename-change-button'))

      expect(screen.getByText('Change "foo.txt" to:')).toBeInTheDocument()
      expect(screen.getByTestId('rename-change-input')).toBeInTheDocument()
    })

    it('when clicks back', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('rename-change-button'))
      expect(screen.getByTestId('rename-change-input')).toBeInTheDocument()

      await userEvent.click(screen.getByTestId('rename-back-button'))
      expect(screen.queryByTestId('rename-change-input')).not.toBeInTheDocument()
    })
  })

  describe('renders footer', () => {
    it('when can overwrite', () => {
      renderComponent()
      expect(screen.queryByTestId('rename-back-button')).not.toBeInTheDocument()
      expect(screen.getByTestId('rename-skip-button')).toBeInTheDocument()
      expect(screen.getByTestId('rename-change-button')).toBeInTheDocument()
      expect(screen.getByTestId('rename-replace-button')).toBeInTheDocument()
    })

    it('when cannot overwrite', () => {
      const fileOptions = {...defaultProps.fileOptions, cannotOverwrite: true}
      renderComponent({fileOptions})
      expect(screen.queryByTestId('rename-back-button')).not.toBeInTheDocument()
      expect(screen.queryByTestId('rename-skip-button')).not.toBeInTheDocument()
      expect(screen.getByTestId('rename-change-button')).toBeInTheDocument()
      expect(screen.queryByTestId('rename-replace-button')).not.toBeInTheDocument()
    })

    it('when is editing', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('rename-change-button'))

      expect(screen.getByTestId('rename-back-button')).toBeInTheDocument()
      expect(screen.queryByTestId('rename-skip-button')).not.toBeInTheDocument()
      expect(screen.getByTestId('rename-change-button')).toBeInTheDocument()
      expect(screen.queryByTestId('rename-replace-button')).not.toBeInTheDocument()
    })
  })

  describe('calls onNameConflictResolved', () => {
    it('when skips', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('rename-skip-button'))

      expect(defaultProps.onNameConflictResolved).toHaveBeenCalledWith({
        dup: 'skip',
        expandZip: false,
        file: textFile,
        name: 'foo.txt',
      })
    })

    it('when changes', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('rename-change-button'))
      await userEvent.clear(screen.getByTestId('rename-change-input'))
      await userEvent.type(screen.getByTestId('rename-change-input'), 'foo2.txt')
      await userEvent.click(screen.getByTestId('rename-change-button'))

      expect(defaultProps.onNameConflictResolved).toHaveBeenCalledWith({
        dup: 'error',
        expandZip: false,
        file: textFile,
        name: 'foo2.txt',
      })
    })

    it('when replaces', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('rename-replace-button'))

      expect(defaultProps.onNameConflictResolved).toHaveBeenCalledWith({
        dup: 'overwrite',
        expandZip: false,
        file: textFile,
        name: 'foo.txt',
      })
    })
  })
})
