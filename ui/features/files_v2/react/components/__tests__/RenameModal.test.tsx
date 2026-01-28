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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {RenameModal} from '../RenameModal'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../fixtures/fakeData'
import {userEvent} from '@testing-library/user-event'
import {Folder, File} from '../../../interfaces/File'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import {RowsProvider} from '../../contexts/RowsContext'
import {mockRowsContext} from '../FileFolderTable/__tests__/testUtils'

const server = setupServer()

const defaultProps: {
  isOpen: boolean
  onClose: any
  renamingItem: File | Folder
} = {
  isOpen: true,
  onClose: vi.fn(),
  renamingItem: FAKE_FILES[0],
}

const renderComponent = (props = {}) => {
  return render(
    <RowsProvider value={mockRowsContext}>
      <RenameModal {...defaultProps} {...props} />
    </RowsProvider>,
  )
}

describe('RenameModal', () => {
  let lastCallBody: string | undefined
  let callCount = 0

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    vi.clearAllMocks()
    lastCallBody = undefined
    callCount = 0
  })

  afterEach(() => {
    server.resetHandlers()
    destroyContainer()
  })

  describe('when renaming a file', () => {
    beforeEach(() => {
      defaultProps.renamingItem = FAKE_FILES[0]

      server.use(
        http.put(`/api/v1/files/${FAKE_FILES[0].id}`, async ({request}) => {
          callCount++
          lastCallBody = await request.text()
          return HttpResponse.json('', {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )
    })

    it('does not send api call when name is the same', async () => {
      const user = userEvent.setup()
      renderComponent()
      expect(await screen.findByText(`Rename`)).toBeInTheDocument()
      await user.click(screen.getByRole('button', {name: 'Save'}))
      await waitFor(() => {
        expect(callCount).toBe(0)
      })
      expect(defaultProps.onClose).toHaveBeenCalled()
    })

    it('validates correctly', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('File Name *')
      await user.clear(input)
      await user.type(input, 'filewith/character')
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(await screen.findByText(`File name cannot contain /`)).toBeInTheDocument()
      await user.clear(input)
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(await screen.findByText(`File name cannot be blank`)).toBeInTheDocument()
      expect(input).toHaveFocus()
    })

    it('validates a name of all spaces correctly', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('File Name *')
      await user.clear(input)
      await user.type(input, ' ')
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(await screen.findByText(`File name cannot be blank`)).toBeInTheDocument()
    })

    it('successfully saves a valid new filename', async () => {
      let requestUrl: string | undefined
      server.use(
        http.put(`/api/v1/files/${FAKE_FILES[0].id}`, ({request}) => {
          requestUrl = request.url
          return HttpResponse.json('')
        }),
      )

      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('File Name *')
      await user.clear(input)
      await user.type(input, 'validfilename')
      await user.click(screen.getByRole('button', {name: 'Save'}))

      await waitFor(() => {
        expect(requestUrl).toContain(`/api/v1/files/${defaultProps.renamingItem.id}`)
      })
    })

    it('displays loading spinner when submitting', async () => {
      const user = userEvent.setup()
      server.use(
        http.put(`/api/v1/files/${FAKE_FILES[0].id}`, () => {
          return new Promise(() => {}) // Never resolves
        }),
      )
      renderComponent()
      const input = screen.getByRole('textbox', {name: 'File Name'})
      await user.clear(input)
      await user.type(input, 'a')
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(screen.getByTestId('rename-spinner')).toBeInTheDocument()
      expect(screen.getByRole('button', {name: 'Cancel'})).toBeDisabled()
      expect(screen.getByRole('button', {name: 'Save'})).toBeDisabled()
    })

    it('does not close when there is an error', async () => {
      const user = userEvent.setup()
      server.use(
        http.put(`/api/v1/files/${FAKE_FILES[0].id}`, () => {
          return new HttpResponse(null, {status: 500})
        }),
      )
      renderComponent()
      const input = screen.getByRole('textbox', {name: 'File Name'})
      await user.clear(input)
      await user.type(input, 'a')
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(defaultProps.onClose).not.toHaveBeenCalled()
    })

    it('submits on enter', async () => {
      let requestUrl: string | undefined
      server.use(
        http.put(`/api/v1/files/${FAKE_FILES[0].id}`, ({request}) => {
          requestUrl = request.url
          return HttpResponse.json('')
        }),
      )

      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByRole('textbox', {name: 'File Name'})
      await user.clear(input)
      await user.type(input, 'anothervalidfilename')
      await user.type(input, '{enter}')
      await waitFor(() => {
        expect(requestUrl).toContain(`/api/v1/files/${defaultProps.renamingItem.id}`)
      })
    })

    it('allows a file name longer than 255 characters', async () => {
      server.use(
        http.put(`/api/v1/files/${FAKE_FILES[0].id}`, async ({request}) => {
          lastCallBody = await request.text()
          return HttpResponse.json('')
        }),
      )

      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('File Name *')
      const name = 'a'.repeat(256)
      // userEvent.type is flaky with long strings
      fireEvent.change(input, {target: {value: name}})
      await user.click(screen.getByRole('button', {name: 'Save'}))
      await waitFor(() => {
        expect(lastCallBody).toEqual(`{"name":"${name}"}`)
      })
    })
  })

  describe('when renaming a folder', () => {
    beforeEach(() => {
      defaultProps.renamingItem = FAKE_FOLDERS[0]

      server.use(
        http.put(`/api/v1/folders/${FAKE_FOLDERS[0].id}`, async ({request}) => {
          callCount++
          lastCallBody = await request.text()
          return HttpResponse.json('', {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )
    })

    it('does not send api call when name is the same', async () => {
      const user = userEvent.setup()
      renderComponent()
      expect(await screen.findByText(`Rename`)).toBeInTheDocument()
      await user.click(screen.getByRole('button', {name: 'Save'}))
      await waitFor(() => {
        expect(callCount).toBe(0)
      })
      expect(defaultProps.onClose).toHaveBeenCalled()
    })

    it('validates correctly', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      await user.clear(input)
      await user.type(input, 'folderwith/character')
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(await screen.findByText(`Folder name cannot contain /`)).toBeInTheDocument()
      await user.clear(input)
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(await screen.findByText(`Folder name cannot be blank`)).toBeInTheDocument()
      expect(input).toHaveFocus()
    })

    it('validates a name of all spaces correctly', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      await user.clear(input)
      await user.type(input, ' ')
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(await screen.findByText(`Folder name cannot be blank`)).toBeInTheDocument()
    })

    it('successfully saves a valid new folder name', async () => {
      let requestUrl: string | undefined
      server.use(
        http.put(`/api/v1/folders/${FAKE_FOLDERS[0].id}`, ({request}) => {
          requestUrl = request.url
          return HttpResponse.json('')
        }),
      )

      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      await user.clear(input)
      await user.type(input, 'validfoldername')
      await user.click(screen.getByRole('button', {name: 'Save'}))
      await waitFor(() => {
        expect(requestUrl).toContain(`/api/v1/folders/${defaultProps.renamingItem.id}`)
      })
    })

    it('does not allow a folder name longer than 255 characters', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      const name = 'a'.repeat(256)
      // userEvent.type is flaky with long strings
      fireEvent.change(input, {target: {value: name}})
      await user.click(screen.getByRole('button', {name: 'Save'}))
      expect(
        await screen.findByText(/Folder name cannot exceed 255 characters/i),
      ).toBeInTheDocument()
    })

    it('does allow a folder name of 255 characters', async () => {
      server.use(
        http.put(`/api/v1/folders/${FAKE_FOLDERS[0].id}`, async ({request}) => {
          lastCallBody = await request.text()
          return HttpResponse.json('')
        }),
      )

      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByLabelText('Folder Name *')
      const name = 'a'.repeat(255)
      // userEvent.type is flaky with long strings
      fireEvent.change(input, {target: {value: name}})
      await user.click(screen.getByRole('button', {name: 'Save'}))
      await waitFor(() => {
        expect(lastCallBody).toEqual(`{"name":"${name}"}`)
      })
    })
  })
})
