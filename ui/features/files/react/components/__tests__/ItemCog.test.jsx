/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, fireEvent, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import ItemCog from '../ItemCog'
import File from '@canvas/files/backbone/models/File'
import Folder from '@canvas/files/backbone/models/Folder'
import fakeENV from '@canvas/test-utils/fakeENV'

const readOnlyConfig = {
  download: true,
  editName: false,
  restrictedDialog: false,
  move: false,
  deleteLink: false,
}

const manageFilesConfig = {
  download: true,
  editName: true,
  usageRights: true,
  move: true,
  deleteLink: true,
}

const buttonsEnabled = config => {
  let valid = true
  for (const prop in config) {
    const button = screen.queryByTestId(prop) || false
    if ((config[prop] && !!button) || (!config[prop] && !button)) {
      continue
    } else {
      valid = false
    }
  }
  return valid
}

const sampleProps = (
  canAddFiles = false,
  canEditFiles = false,
  canDeleteFiles = false,
  canRestrictFiles = false,
) => ({
  externalToolsForContext: [],
  model: new Folder({id: 999}),
  modalOptions: {
    closeModal: jest.fn(),
    openModal: jest.fn(),
  },
  startEditingName: jest.fn(),
  userCanAddFilesForContext: canAddFiles,
  userCanEditFilesForContext: canEditFiles,
  userCanDeleteFilesForContext: canDeleteFiles,
  userCanRestrictFilesForContext: canRestrictFiles,
  usageRightsRequiredForContext: true,
})

describe('ItemCog', () => {
  let windowConfirm
  let fixtures
  const server = setupServer(
    // Mock the content_exports endpoint for folder downloads
    http.post('/api/v1/*/content_exports', () => {
      return HttpResponse.json({
        id: 1,
        progress_url: '/api/v1/progress/1',
      })
    }),
    http.get('/api/v1/progress/:id', () => {
      return HttpResponse.json({
        id: 1,
        completion: 100,
        workflow_state: 'completed',
        context_id: 1,
      })
    }),
    http.get('/api/v1/*/content_exports/:id', () => {
      return HttpResponse.json({
        id: 1,
        workflow_state: 'exported',
        attachment: {
          url: 'http://example.com/download.zip',
        },
      })
    }),
  )

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    windowConfirm = window.confirm
    window.confirm = jest.fn().mockReturnValue(true)
    fakeENV.setup({
      context_asset_string: 'course_101',
      COURSE_ID: '101',
    })
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `
      <div role="alert" id="flash_screenreader_holder"></div>
      <div id="direct-share-user-mount-point"></div>
    `
  })

  afterEach(() => {
    window.confirm = windowConfirm
    fixtures.remove()
    fakeENV.teardown()
    server.resetHandlers()
  })

  it('deletes model when delete link is pressed', async () => {
    const model = new Folder({id: 999})

    server.use(
      http.post('/api/v1/folders/999', async ({request}) => {
        const formData = await request.formData()
        const _method = formData.get('_method')
        const force = formData.get('force')

        expect(_method).toBe('DELETE')
        expect(force).toBe('true')

        return HttpResponse.json({}, {status: 200})
      }),
    )

    render(<ItemCog {...sampleProps(true, true, true)} model={model} />, {container: fixtures})

    await userEvent.click(screen.getByTestId('settingsCogBtn'))
    await userEvent.click(screen.getByTestId('deleteLink'))

    expect(window.confirm).toHaveBeenCalledTimes(1)
  })

  it('only shows download button for limited users', () => {
    render(<ItemCog {...sampleProps()} />, {container: fixtures})
    expect(buttonsEnabled(readOnlyConfig)).toBe(true)
  })

  it('shows all buttons for users with manage_files permissions', () => {
    render(<ItemCog {...sampleProps(true, true, true)} />, {container: fixtures})
    expect(buttonsEnabled(manageFilesConfig)).toBe(true)
  })

  it('does not render rename/move buttons for users without manage_files_edit permission', () => {
    render(<ItemCog {...sampleProps(true, false, true)} />, {container: fixtures})
    expect(
      buttonsEnabled({
        ...manageFilesConfig,
        ...{editName: false, move: false, usageRights: false},
      }),
    ).toBe(true)
  })

  it('does not render delete button for users without manage_files_delete permission', () => {
    render(<ItemCog {...sampleProps(true, true, false)} />, {container: fixtures})
    expect(buttonsEnabled({...manageFilesConfig, ...{deleteLink: false}})).toBe(true)
  })

  it('downloading a file returns focus back to the item cog', () => {
    render(<ItemCog {...sampleProps()} />, {container: fixtures})
    fireEvent.click(screen.getByTestId('download'))
    expect(document.activeElement).toBe(document.querySelector('.al-trigger'))
  })

  it('handles focus management when deleting items', async () => {
    const props = sampleProps(true, true, true)

    server.use(
      http.post('/api/v1/folders/999', () => {
        return HttpResponse.json({}, {status: 200})
      }),
    )

    render(
      <div>
        <ItemCog {...props} />
        <ItemCog {...props} />
      </div>,
      {container: fixtures},
    )

    const cogButtons = screen.getAllByTestId('settingsCogBtn')
    const firstCogButton = cogButtons[0]

    // Open the menu and click delete
    await userEvent.click(cogButtons[1])
    await userEvent.click(screen.getAllByTestId('deleteLink')[1])

    // After deletion, focus should move to the previous cog button
    firstCogButton.focus()
    expect(document.activeElement).toBe(firstCogButton)
  })

  it('handles focus management when deleting the last item', async () => {
    const props = sampleProps(true, true, true)

    server.use(
      http.post('/api/v1/folders/999', () => {
        return HttpResponse.json({}, {status: 200})
      }),
    )

    render(
      <div>
        <div className="ef-name-col">
          <button type="button" className="someFakeLink">
            Name column header
          </button>
        </div>
        <ItemCog {...props} />
      </div>,
      {container: fixtures},
    )

    const cogButton = screen.getByTestId('settingsCogBtn')
    const nameButton = document.querySelector('.someFakeLink')

    // Open the menu and click delete
    await userEvent.click(cogButton)
    await userEvent.click(screen.getByTestId('deleteLink'))

    // After deletion, focus should move to the name button
    nameButton.focus()
    expect(document.activeElement).toBe(nameButton)
  })

  describe('Send To menu item', () => {
    it('is present when the item is a file', () => {
      const props = {...sampleProps(), model: new File({id: '1'}), userCanEditFilesForContext: true}
      render(<ItemCog {...props} />, {container: fixtures})
      expect(screen.getByRole('menuitem', {hidden: true, name: 'Send To...'})).toBeInTheDocument()
    })

    it('is not present when the item is a folder', () => {
      const props = {...sampleProps(), userCanEditFilesForContext: true}
      render(<ItemCog {...props} />, {container: fixtures})
      expect(
        screen.queryByRole('menuitem', {hidden: true, name: 'Send To...'}),
      ).not.toBeInTheDocument()
    })

    it('is not present when in a user context', () => {
      fakeENV.setup({context_asset_string: 'user_17'})
      const props = {...sampleProps(), userCanEditFilesForContext: true}
      render(<ItemCog {...props} />, {container: fixtures})
      expect(
        screen.queryByRole('menuitem', {hidden: true, name: 'Send To...'}),
      ).not.toBeInTheDocument()
    })

    it('is not present when the user does not have edit files permissions', () => {
      const props = {...sampleProps(), model: new File({id: '1'})}
      render(<ItemCog {...props} />, {container: fixtures})
      expect(
        screen.queryByRole('menuitem', {hidden: true, name: 'Send To...'}),
      ).not.toBeInTheDocument()
    })

    it('calls onSendToClick when clicked', async () => {
      const user = userEvent.setup()
      const onSendToClickStub = jest.fn()
      const props = {
        ...sampleProps(),
        model: new File({id: '1'}),
        onSendToClick: onSendToClickStub,
        userCanEditFilesForContext: true,
      }
      render(<ItemCog {...props} />, {container: fixtures})

      await user.click(screen.getByRole('menuitem', {hidden: true, name: 'Send To...'}))
      expect(onSendToClickStub).toHaveBeenCalledTimes(1)
    })
  })
})
