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
import {render, fireEvent, screen, within} from '@testing-library/react'
import ReactModal from 'react-modal'
import FileRenameForm from '../FileRenameForm'

describe('FileRenameForm', () => {
  const defaultProps = {
    fileOptions: {
      file: {
        id: 999,
        name: 'original_name.txt',
      },
      name: 'options_name.txt',
    },
    onNameConflictResolved: () => {},
    closeOnResolve: true,
  }

  beforeEach(() => {
    const root = document.createElement('div')
    root.setAttribute('id', 'flash_screenreader_holder')
    document.body.appendChild(root)
    ReactModal.setAppElement(document.body)
  })

  afterEach(() => {
    const root = document.getElementById('flash_screenreader_holder')
    if (root) {
      document.body.removeChild(root)
    }
  })

  const renderFileRenameForm = (props = {}) => {
    return render(<FileRenameForm {...defaultProps} {...props} />)
  }

  const getModalContent = () => {
    return screen.getByTestId('canvas-modal')
  }

  it('switches to editing file name state with button click', () => {
    renderFileRenameForm()
    const modal = getModalContent()
    const renameButton = within(modal).getByText('Change Name')

    fireEvent.click(renameButton)

    expect(within(modal).getByLabelText('File name')).toBeInTheDocument()
  })

  it('displays options name by default when editing', () => {
    renderFileRenameForm()
    const modal = getModalContent()

    fireEvent.click(within(modal).getByText('Change Name'))

    expect(within(modal).getByLabelText('File name')).toHaveValue('options_name.txt')
  })

  it('displays file name when no options name exists', () => {
    const props = {
      fileOptions: {
        file: {name: 'file_name.md'},
      },
    }
    renderFileRenameForm(props)
    const modal = getModalContent()

    fireEvent.click(within(modal).getByText('Change Name'))

    expect(within(modal).getByLabelText('File name')).toHaveValue('file_name.md')
  })

  it('can go back from editing to initial view', () => {
    renderFileRenameForm()
    const modal = getModalContent()

    fireEvent.click(within(modal).getByText('Change Name'))
    expect(within(modal).getByLabelText('File name')).toBeInTheDocument()

    fireEvent.click(within(modal).getByText('Back'))
    expect(within(modal).queryByLabelText('File name')).not.toBeInTheDocument()
    expect(within(modal).getByText('Replace')).toBeInTheDocument()
  })

  it('calls onNameConflictResolved when committing changes', () => {
    const onNameConflictResolved = jest.fn()
    const props = {
      fileOptions: {file: {name: 'file_name.md'}},
      onNameConflictResolved,
    }
    renderFileRenameForm(props)
    const modal = getModalContent()

    fireEvent.click(within(modal).getByText('Change Name'))
    fireEvent.click(within(modal).getByText('Change'))

    expect(onNameConflictResolved).toHaveBeenCalled()
    expect(onNameConflictResolved.mock.calls[0][0]).toHaveProperty('name')
  })

  it('preserves expandZip option when skipping', () => {
    const onNameConflictResolved = jest.fn()
    const props = {
      fileOptions: {
        file: {name: 'file_name.zip'},
        expandZip: true,
      },
      allowSkip: true,
      onNameConflictResolved,
    }
    renderFileRenameForm(props)
    const modal = getModalContent()

    fireEvent.click(within(modal).getByText('Skip'))

    expect(onNameConflictResolved).toHaveBeenCalledWith(
      expect.objectContaining({
        expandZip: true,
      }),
    )
  })

  it('preserves expandZip option when renaming', () => {
    const onNameConflictResolved = jest.fn()
    const props = {
      fileOptions: {
        file: {name: 'file_name.zip'},
        expandZip: true,
      },
      onNameConflictResolved,
    }
    renderFileRenameForm(props)
    const modal = getModalContent()

    fireEvent.click(within(modal).getByText('Change Name'))
    fireEvent.click(within(modal).getByText('Change'))

    expect(onNameConflictResolved).toHaveBeenCalledWith(
      expect.objectContaining({
        expandZip: true,
      }),
    )
  })

  it('preserves expandZip option when replacing', () => {
    const onNameConflictResolved = jest.fn()
    const props = {
      fileOptions: {
        file: {name: 'file_name.zip'},
        expandZip: true,
      },
      onNameConflictResolved,
    }
    renderFileRenameForm(props)
    const modal = getModalContent()

    fireEvent.click(within(modal).getByText('Replace'))

    expect(onNameConflictResolved).toHaveBeenCalledWith(
      expect.objectContaining({
        expandZip: true,
      }),
    )
  })

  it('renders default rename file message', () => {
    const {getByText} = renderFileRenameForm()

    expect(getByText(/An item named "options_name.txt" already exists/)).toBeInTheDocument()
  })

  it('renders custom rename message when provided', () => {
    const customMessage = 'Custom rename message for options_name.txt'
    const props = {
      onRenameFileMessage: name => `Custom rename message for ${name}`,
    }
    const {getByText} = renderFileRenameForm(props)

    expect(getByText(customMessage)).toBeInTheDocument()
  })

  it('renders default lock file message when file cannot be overwritten', () => {
    const props = {
      fileOptions: {
        file: {
          id: 999,
          name: 'original_name.txt',
        },
        name: 'options_name.txt',
        cannotOverwrite: true,
      },
    }
    const {getByText} = renderFileRenameForm(props)

    expect(getByText(/A locked item named "options_name.txt" already exists/)).toBeInTheDocument()
  })

  it('renders custom lock file message when provided', () => {
    const props = {
      fileOptions: {
        file: {
          id: 999,
          name: 'original_name.txt',
        },
        name: 'options_name.txt',
        cannotOverwrite: true,
      },
      onLockFileMessage: name => `Custom lock message for ${name}`,
    }
    const {getByText} = renderFileRenameForm(props)

    expect(getByText('Custom lock message for options_name.txt')).toBeInTheDocument()
  })
})
