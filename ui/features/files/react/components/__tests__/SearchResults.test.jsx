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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {merge} from 'es-toolkit/compat'
import FilesCollection from '@canvas/files/backbone/collections/FilesCollection'
import Folder from '@canvas/files/backbone/models/Folder'
import SearchResults from '../SearchResults'
import fakeENV from '@canvas/test-utils/fakeENV'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

// MSW server for this test suite
const server = setupServer(
  // Files API endpoints
  http.get('*/api/v1/courses/:courseId/files', () => {
    return HttpResponse.json([])
  }),
  http.get('*/api/v1/users/:userId/files', () => {
    return HttpResponse.json([])
  }),
  http.get('*/api/v1/groups/:groupId/files', () => {
    return HttpResponse.json([])
  }),
  // Generic Canvas API catch-all
  http.get('*/api/v1/*', () => {
    return HttpResponse.json({})
  }),
  http.post('*/api/v1/*', () => {
    return HttpResponse.json({})
  }),
)

const defaultProps = (props = {}) => {
  const ref = document.createElement('div')
  const folder = new Folder()
  folder.files.loadedAll = true
  folder.folders.loadedAll = true

  return merge(
    {
      contextType: 'courses',
      contextId: 1,
      collection: new FilesCollection([{id: '1'}]),
      filesDirectoryRef: ref,
      currentFolder: folder,
      externalToolsForContext: [],
      params: {},
      areAllItemsSelected: () => {},
      query: {},
      modalOptions: {},
      pathname: '/',
      previewItem: () => {},
      toggleItemSelected: () => {},
      userCanAddFilesForContext: true,
      userCanEditFilesForContext: true,
      userCanRestrictFilesForContext: true,
      userCanDeleteFilesForContext: true,
      usageRightsRequiredForContext: true,
      splat: '',
      toggleAllSelected: () => {},
      selectedItems: [],
      dndOptions: {},
      clearSelectedItems: () => {},
      onMove: () => {},
      onResolvePath: () => {},
    },
    props,
  )
}

describe('SearchResults', () => {
  beforeAll(() => {
    // Start MSW server before all tests
    server.listen({
      onUnhandledRequest: 'bypass',
    })
  })

  afterAll(() => {
    // Clean up MSW server after all tests
    server.close()
  })

  beforeEach(() => {
    userEvent.setup()
    fakeENV.setup({
      COURSE_ID: '101',
      context_asset_string: 'course_17',
      API_URL: 'http://localhost:3000',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    // Reset MSW handlers after each test
    server.resetHandlers()
  })

  describe('accessibility message', () => {
    let wrapper

    beforeEach(() => {
      document.body.appendChild(document.createElement('div'))
    })

    it('renders if userCanEditFilesForContext is true', () => {
      render(<SearchResults {...defaultProps()} />, {attachTo: document.body.firstChild})
      const message = document.querySelector('.SearchResults__accessbilityMessage')
      expect(message).toBeInTheDocument()
    })

    it('does not render if userCanEditFilesForContext is false', () => {
      render(<SearchResults {...defaultProps({userCanEditFilesForContext: false})} />, {
        attachTo: document.body.firstChild,
      })
      const message = document.querySelector('.SearchResults__accessbilityMessage')
      expect(message).not.toBeInTheDocument()
    })
  })

  describe('File Menu', () => {
    let ref, menuItems

    beforeEach(() => {
      document.body.appendChild(document.createElement('div'))
      const props = {...defaultProps()}
      const collection = new FilesCollection([
        {id: '1', created_at: '2022-01-01T00:00:00', modified_at: '2022-01-01T00:00:00'},
      ])
      ref = React.createRef()
      render(<SearchResults {...props} ref={ref} />, {attachTo: document.body.firstChild})
      ref.current.setState({collection})

      menuItems = Array.from(document.body.querySelectorAll('.al-options [role="menuitem"]'))
    })

    describe('Download item', () => {
      it('renders', () => {
        expect(menuItems.some(i => i.textContent === 'Download')).toEqual(true)
      })
    })

    describe('Send To item', () => {
      it('renders', () => {
        expect(menuItems.some(i => i.textContent === 'Send To...')).toEqual(true)
      })

      it('renders a modal for sending the file, when clicked', () => {
        ref.current.setState({sendFileId: '1'})
        expect(document.body.querySelector('[role="dialog"][aria-label="Send To..."]')).toBeTruthy()
      })
    })

    describe('Copy To item', () => {
      it('renders', () => {
        expect(menuItems.some(i => i.textContent === 'Copy To...')).toEqual(true)
      })

      it('renders a modal for sending the file, when clicked', () => {
        ref.current.setState({copyFileId: '1'})
        expect(document.body.querySelector('[role="dialog"][aria-label="Copy To..."]')).toBeTruthy()
      })
    })

    it('Rename item renders', () => {
      expect(menuItems.some(i => i.textContent === 'Rename')).toEqual(true)
    })

    it('Move item renders', () => {
      expect(menuItems.some(i => i.textContent === 'Move To...')).toEqual(true)
    })

    it('Delete item renders', () => {
      expect(menuItems.some(i => i.textContent === 'Delete')).toEqual(true)
    })
  })
})
