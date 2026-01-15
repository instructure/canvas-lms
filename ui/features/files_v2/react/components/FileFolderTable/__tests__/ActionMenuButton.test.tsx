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
import '@canvas/files/mockFilesENV'
import {BrowserRouter as Router} from 'react-router-dom'
import ActionMenuButton, {ActionMenuButtonProps} from '../ActionMenuButton'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../../fixtures/fakeData'
import {
  FileManagementProvider,
  FileManagementContextProps,
} from '../../../contexts/FileManagementContext'
import {RowFocusProvider} from '../../../contexts/RowFocusContext'
import {RowsProvider} from '../../../contexts/RowsContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
import {mockRowFocusContext, mockRowsContext} from './testUtils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import userEvent from '@testing-library/user-event'
import {assignLocation} from '@canvas/util/globalUtils'
import {downloadZip} from '../../../../utils/downloadUtils'

const server = setupServer()

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn().mockReturnValue(() => {}),
}))

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
}))

vi.mock('../../../../utils/downloadUtils', () => ({
  downloadZip: vi.fn(),
}))

const defaultProps: ActionMenuButtonProps = {
  size: 'large',
  userCanEditFilesForContext: true,
  userCanDeleteFilesForContext: true,
  userCanRestrictFilesForContext: true,
  usageRightsRequiredForContext: true,
  row: FAKE_FILES[0],
  rowIndex: 0,
}

const renderComponent = (
  props: ActionMenuButtonProps = {...defaultProps},
  context: Partial<FileManagementContextProps> = {},
) => {
  return render(
    <Router>
      <FileManagementProvider value={createMockFileManagementContext(context)}>
        <RowFocusProvider value={mockRowFocusContext}>
          <RowsProvider value={mockRowsContext}>
            <ActionMenuButton {...defaultProps} {...props} />
          </RowsProvider>
        </RowFocusProvider>
      </FileManagementProvider>
    </Router>,
  )
}

describe('ActionMenuButton', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
    if (ENV.FEATURES?.restrict_student_access !== undefined) {
      delete ENV.FEATURES.restrict_student_access
    }
  })
  afterAll(() => server.close())

  describe('when item is a file', () => {
    it('renders all items for file type', async () => {
      const user = userEvent.setup()
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.getByText('Send To...')).toBeInTheDocument()
        expect(screen.getByText('Copy To...')).toBeInTheDocument()
        expect(screen.getByText('Move To...')).toBeInTheDocument()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('does not render move button for file when student access is restricted', async () => {
      ENV.FEATURES = {restrict_student_access: true}
      ENV.current_user_roles = ['student']

      const user = userEvent.setup()
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.queryByText('Download')).toBeNull()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.getByText('Send To...')).toBeInTheDocument()
        expect(screen.getByText('Copy To...')).toBeInTheDocument()
        expect(screen.queryByText('Move To...')).toBeNull()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('does not render download button for file when student access is restricted', async () => {
      ENV.FEATURES = {restrict_student_access: true}
      ENV.current_user_roles = ['student']

      const user = userEvent.setup()
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      await user.click(button)

      await waitFor(() => {
        expect(screen.queryByText('Download')).toBeNull()
      })
    })

    it('renders items when context is groups', async () => {
      const user = userEvent.setup()
      renderComponent(
        {...defaultProps, userCanRestrictFilesForContext: false},
        {contextType: 'groups'},
      )

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.queryByText('Edit Permissions')).toBeNull()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.queryByText('Send To...')).toBeNull()
        expect(screen.queryByText('Copy To...')).toBeNull()
        expect(screen.getByText('Move To...')).toBeInTheDocument()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('does not render items when userCanEditFilesForContext is false', async () => {
      const user = userEvent.setup()
      // if userCanEditFilesForContext is false, userCanRestrictFilesForContext will also be false
      renderComponent({
        ...defaultProps,
        userCanEditFilesForContext: false,
        userCanRestrictFilesForContext: false,
      })

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.queryByText('Rename')).toBeNull()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.queryByText('Edit Permissions')).toBeNull()
        expect(screen.queryByText('Manage Usage Rights')).toBeNull()
        expect(screen.queryByText('Send To...')).toBeNull()
        expect(screen.queryByText('Copy To...')).toBeNull()
        expect(screen.queryByText('Move To...')).toBeNull()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('does not render items when userCanDeleteFilesForContext is false', async () => {
      const user = userEvent.setup()
      renderComponent({...defaultProps, userCanDeleteFilesForContext: false})

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.getByText('Send To...')).toBeInTheDocument()
        expect(screen.getByText('Copy To...')).toBeInTheDocument()
        expect(screen.getByText('Move To...')).toBeInTheDocument()
        expect(screen.queryByText('Delete')).toBeNull()
      })
    })

    it('does not render items when usageRightsRequiredForContext is false', async () => {
      const user = userEvent.setup()
      renderComponent({...defaultProps, usageRightsRequiredForContext: false})

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.queryByText('Manage Usage Rights')).toBeNull()
        expect(screen.getByText('Send To...')).toBeInTheDocument()
        expect(screen.getByText('Copy To...')).toBeInTheDocument()
        expect(screen.getByText('Move To...')).toBeInTheDocument()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('does not render items when locked by blueprint', async () => {
      const user = userEvent.setup()
      renderComponent({
        ...defaultProps,
        row: {
          ...FAKE_FILES[0],
          ...{restricted_by_master_course: true, is_master_course_child_content: true},
        },
      })

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.queryByText('Rename')).toBeNull()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.getByText('Send To...')).toBeInTheDocument()
        expect(screen.getByText('Copy To...')).toBeInTheDocument()
        expect(screen.queryByText('Move To...')).toBeNull()
        expect(screen.queryByText('Delete')).toBeNull()
      })
    })

    it('render small size button', async () => {
      renderComponent({...defaultProps, size: 'small'})

      const button = screen.getByTestId('action-menu-button-small')
      expect(button).toBeInTheDocument()
    })

    it('opens the rename modal', async () => {
      const user = userEvent.setup()
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      await user.click(button)

      const renameButton = await screen.findByText('Rename')
      await user.click(renameButton)

      await waitFor(() => {
        expect(screen.getByRole('heading', {name: 'Rename'})).toBeInTheDocument()
      })
    })

    it('closes and reopens the rename modal without clearing the name', async () => {
      const user = userEvent.setup()
      renderComponent()
      const menuButton = await screen.findByRole('button', {
        name: `Actions for "${FAKE_FILES[0].display_name}"`,
      })
      await user.click(menuButton)
      // can't just re-use the variable because it gets removed from DOM
      const renameButton = async () => await screen.findByRole('menuitem', {name: 'Rename'})
      await user.click(await renameButton())

      const input = async () => await screen.findByRole('textbox', {name: 'File Name'})
      expect(await input()).toHaveValue(FAKE_FILES[0].name)

      const cancelButton = screen.getByRole('button', {name: 'Cancel'})
      await user.click(cancelButton)
      // necessary for onExited to fire
      await waitFor(() => {
        expect(screen.queryByRole('heading', {name: 'Rename', hidden: true})).toBeNull()
      })

      await user.click(menuButton)
      await user.click(await renameButton())
      expect(await input()).toHaveValue(FAKE_FILES[0].name)
    })

    it('launches LTI on click', async () => {
      const user = userEvent.setup()
      const fileMenuTools = [
        {
          id: '1',
          title: 'Tool',
          base_url: 'http://example.com',
          icon_url: '',
        },
      ]
      renderComponent({...defaultProps}, {fileMenuTools})
      const menuButton = screen.getByTestId('action-menu-button-large')
      await user.click(menuButton)

      const toolButton = await screen.findByText('Tool')
      await user.click(toolButton)

      expect(assignLocation).toHaveBeenCalledWith(`http://example.com&files[]=${FAKE_FILES[0].id}`)
    })

    it('displays multiple LTI tools', async () => {
      const user = userEvent.setup()
      const fileMenuTools = [
        {id: '1', title: 'Tool1', base_url: 'http://toolone.com', icon_url: ''},
        {id: '2', title: 'Tool2', base_url: 'http://tooltwo.com', icon_url: ''},
      ]
      renderComponent({...defaultProps}, {fileMenuTools})
      const menuButton = screen.getByTestId('action-menu-button-large')
      await user.click(menuButton)
      expect(await screen.findByText('Tool1')).toBeInTheDocument()
      expect(await screen.findByText('Tool2')).toBeInTheDocument()
    })
  })

  describe('when item is a folder', () => {
    const folderProps = {...defaultProps, row: FAKE_FOLDERS[0]}

    it('renders all items for folder type', async () => {
      const user = userEvent.setup()
      renderComponent(folderProps)

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.getByText('Move To...')).toBeInTheDocument()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('does not render move button for folder when student access is restricted', async () => {
      ENV.FEATURES = {restrict_student_access: true}
      ENV.current_user_roles = ['student']

      const user = userEvent.setup()
      renderComponent(folderProps)

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.queryByText('Download')).toBeNull()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.queryByText('Move To...')).toBeNull()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })
    it('does call correct download API with correct parameters', async () => {
      const user = userEvent.setup()
      renderComponent(folderProps)

      const button = screen.getByTestId('action-menu-button-large')
      await user.click(button)

      const downloadButton = await screen.findByText('Download')
      await user.click(downloadButton)

      const expectedArguments = new Set([`folder-${FAKE_FOLDERS[0].id}`])
      expect(downloadZip).toHaveBeenCalledWith(expectedArguments)
    })

    it('opens the rename modal', async () => {
      const user = userEvent.setup()
      renderComponent(folderProps)

      const button = screen.getByTestId('action-menu-button-large')
      await user.click(button)

      const renameButton = await screen.findByText('Rename')
      await user.click(renameButton)

      await waitFor(() => {
        expect(screen.getByRole('heading', {name: 'Rename'})).toBeInTheDocument()
      })
    })

    it('does not display LTI button', async () => {
      const user = userEvent.setup()
      const fileMenuTools = [
        {id: '1', title: 'Tool1', base_url: 'http://toolone.com', icon_url: ''},
      ]
      renderComponent(folderProps, {fileMenuTools})
      const menuButton = screen.getByTestId('action-menu-button-large')
      await user.click(menuButton)
      // necessary to make sure the menu is open
      expect(await screen.findByText('Rename')).toBeInTheDocument()
      expect(screen.queryByText('Tool1')).not.toBeInTheDocument()
    })
  })

  describe('Delete behavior', () => {
    const fileProps = {...defaultProps, row: FAKE_FILES[0]}

    beforeEach(() => {
      server.use(
        http.delete(/.*\/files\/\d+/, () => {
          return new HttpResponse(null, {status: 200})
        }),
        http.delete(/.*\/folders\/\d+/, () => {
          return new HttpResponse(null, {status: 200})
        }),
      )
    })

    it('opens delete modal when delete button is clicked', async () => {
      const user = userEvent.setup()
      renderComponent(fileProps)

      const button = screen.getByTestId('action-menu-button-large')
      await user.click(button)

      const deleteButton = await screen.findByText('Delete')
      await user.click(deleteButton)

      expect(
        await screen.findByText('Deleting this item cannot be undone. Do you want to continue?'),
      ).toBeInTheDocument()
    })

    it('renders flash error when delete fails', async () => {
      const user = userEvent.setup()
      server.use(
        http.delete(/.*\/files\/178/, () => {
          return new HttpResponse(null, {status: 500})
        }),
      )
      renderComponent(fileProps)

      const button = screen.getByTestId('action-menu-button-large')
      await user.click(button)

      const deleteButton = await screen.findByText('Delete')
      await user.click(deleteButton)

      const confirmButton = await screen.getByTestId('modal-delete-button')
      await user.click(confirmButton)

      await waitFor(() => {
        expect(showFlashError).toHaveBeenCalledWith(
          'Failed to delete the selected item. Please try again.',
        )
      })
    })

    it('does not render "Delete" when userCanDeleteFilesForContext is false', async () => {
      const user = userEvent.setup()
      renderComponent({...fileProps, userCanDeleteFilesForContext: false})

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      await user.click(button)
      await waitFor(() => {
        expect(screen.queryByText('Delete')).toBeNull()
      })
    })
  })
})
