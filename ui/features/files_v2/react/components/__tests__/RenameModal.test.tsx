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
import {RenameModal} from '../RenameModal'
import fetchMock from 'fetch-mock'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'
import {userEvent} from '@testing-library/user-event'
import {Folder, File} from '../../../interfaces/File'

const defaultProps: {
  isOpen: boolean
  onClose: jest.Mock
  renamingItem: File | Folder
} = {
  isOpen: true,
  onClose: jest.fn(),
  renamingItem: FAKE_FILES[0],
}

const renderComponent = (props = {}) => {
  return render(<RenameModal {...defaultProps} {...props} />)
}

describe('RenameModal', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  describe('when renaming a file', () => {
    beforeEach(() => {
      defaultProps.renamingItem = FAKE_FILES[0]

      fetchMock.put(`/api/v1/files/${FAKE_FILES[0].id}`, {
        status: 200,
        headers: {'Content-Type': 'application/json'},
        body: '',
      })
    })

    it('does not send api call when name is the same', async () => {
      renderComponent()
      expect(await screen.findByText(`Rename`)).toBeInTheDocument()
      screen.getByText('Save').click()
      await waitFor(() => {
        expect(fetchMock.calls()).toHaveLength(0)
        expect(defaultProps.onClose).toHaveBeenCalled()
      })
    })

    it('validates correctly', async () => {
      const user = userEvent.setup({delay: null})
      renderComponent()
      const input = screen.getByLabelText('File Name *')
      await user.type(input, 'filewith/character')
      screen.getByText('Save').click()
      expect(await screen.findByText(`File name cannot contain /`)).toBeInTheDocument()
      await user.clear(input)
      screen.getByText('Save').click()
      expect(await screen.findByText(`File name cannot be blank`)).toBeInTheDocument()
    })

    it('validates a name of all spaces correctly', async () => {
      const user = userEvent.setup({delay: null})
      renderComponent()
      const input = screen.getByLabelText('File Name *')
      await user.clear(input)
      await user.type(input, ' ')
      screen.getByText('Save').click()
      expect(await screen.findByText(`File name cannot be blank`)).toBeInTheDocument()
    })

    it('successfully saves a valid new filename', async () => {
      const user = userEvent.setup({delay: null})
      renderComponent()
      const input = screen.getByLabelText('File Name *')
      await user.type(input, 'validfilename')
      screen.getByText('Save').click()

      await waitFor(() => {
        expect(fetchMock.calls()).toHaveLength(1)
        expect(fetchMock.calls()[0][0]).toBe(`/api/v1/files/${defaultProps.renamingItem.id}`)
      })
    })
  })

  describe('when renaming a folder', () => {
    beforeEach(() => {
      defaultProps.renamingItem = FAKE_FOLDERS[0]

      fetchMock.put(`/api/v1/folders/${FAKE_FOLDERS[0].id}`, {
        status: 200,
        headers: {'Content-Type': 'application/json'},
        body: '',
      })
    })

    it('does not send api call when name is the same', async () => {
      renderComponent()
      expect(await screen.findByText(`Rename`)).toBeInTheDocument()
      screen.getByText('Save').click()
      await waitFor(() => {
        expect(fetchMock.calls()).toHaveLength(0)
        expect(defaultProps.onClose).toHaveBeenCalled()
      })
    })

    it('validates correctly', async () => {
      const user = userEvent.setup({delay: null})
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      await user.type(input, 'folderwith/character')
      screen.getByText('Save').click()
      expect(await screen.findByText(`Folder name cannot contain /`)).toBeInTheDocument()
      await user.clear(input)
      screen.getByText('Save').click()
      expect(await screen.findByText(`Folder name cannot be blank`)).toBeInTheDocument()
    })

    it('validates a name of all spaces correctly', async () => {
      const user = userEvent.setup({delay: null})
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      await user.clear(input)
      await user.type(input, ' ')
      screen.getByText('Save').click()
      expect(await screen.findByText(`Folder name cannot be blank`)).toBeInTheDocument()
    })

    it('successfully saves a valid new folder name', async () => {
      const user = userEvent.setup({delay: null})
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      await user.type(input, 'validfoldername')
      screen.getByText('Save').click()

      await waitFor(() => {
        expect(fetchMock.calls()).toHaveLength(1)
        expect(fetchMock.calls()[0][0]).toBe(`/api/v1/folders/${defaultProps.renamingItem.id}`)
      })
    })
  })
})
