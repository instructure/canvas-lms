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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import ActionMenuButton from '../ActionMenuButton'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../../fixtures/fakeData'
import {FileManagementContext} from '../../Contexts'

let defaultProps: any
let defaultContext: any

const renderComponent = (props = {}, context = {}) => {
  return render(
    <FileManagementContext.Provider value={{...defaultContext, ...context}}>
      <ActionMenuButton {...defaultProps} {...props} />
    </FileManagementContext.Provider>,
  )
}

describe('ActionMenuButton', () => {
  beforeEach(() => {
    defaultProps = {
      size: 'large',
      userCanEditFilesForContext: true,
      userCanDeleteFilesForContext: true,
      usageRightsRequiredForContext: true,
      row: FAKE_FILES[0],
    }
    defaultContext = {
      contextType: 'course',
      contextId: '1',
      folderId: '1',
      showingAllContexts: false,
    }
  })

  describe('when item is a file', () => {
    beforeEach(() => {
      defaultProps.row = FAKE_FILES[0]
    })

    it('renders all items for file type', async () => {
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      fireEvent.click(button)
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

    it('renders items when context is groups', async () => {
      renderComponent({}, {contextType: 'groups'})

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      fireEvent.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.queryByText('Manage Usage Rights')).toBeNull()
        expect(screen.queryByText('Send To...')).toBeNull()
        expect(screen.queryByText('Copy To...')).toBeNull()
        expect(screen.getByText('Move To...')).toBeInTheDocument()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('does not renders items when userCanEditFilesForContext is false', async () => {
      renderComponent({userCanEditFilesForContext: false})

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      fireEvent.click(button)
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

    it('does not renders items when userCanDeleteFilesForContext is false', async () => {
      renderComponent({userCanDeleteFilesForContext: false})

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      fireEvent.click(button)
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

    it('does not renders items when usageRightsRequiredForContext is false', async () => {
      renderComponent({usageRightsRequiredForContext: false})

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      fireEvent.click(button)
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

    it('does not renders items when when locked by blueprint', async () => {
      renderComponent({
        row: {
          ...FAKE_FILES[0],
          ...{restricted_by_master_course: true, is_master_course_child_content: true},
        },
      })

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      fireEvent.click(button)
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
      renderComponent({size: 'small'})

      const button = screen.getByTestId('action-menu-button-small')
      expect(button).toBeInTheDocument()
    })

    it('opens the rename modal', async () => {
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      fireEvent.click(button)

      const renameButton = await screen.findByText('Rename')
      fireEvent.click(renameButton)

      await waitFor(() => {
        expect(screen.getByRole('heading', {name: 'Rename'})).toBeInTheDocument()
      })
    })
  })

  describe('when item is a folder', () => {
    beforeEach(() => {
      defaultProps.row = FAKE_FOLDERS[0]
    })

    it('renders all items for folder type', async () => {
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      expect(button).toBeInTheDocument()

      fireEvent.click(button)
      await waitFor(() => {
        expect(screen.getByText('Rename')).toBeInTheDocument()
        expect(screen.getByText('Download')).toBeInTheDocument()
        expect(screen.getByText('Edit Permissions')).toBeInTheDocument()
        expect(screen.getByText('Manage Usage Rights')).toBeInTheDocument()
        expect(screen.getByText('Move To...')).toBeInTheDocument()
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })
    })

    it('opens the rename modal', async () => {
      renderComponent()

      const button = screen.getByTestId('action-menu-button-large')
      fireEvent.click(button)

      const renameButton = await screen.findByText('Rename')
      fireEvent.click(renameButton)

      await waitFor(() => {
        expect(screen.getByRole('heading', {name: 'Rename'})).toBeInTheDocument()
      })
    })
  })
})
