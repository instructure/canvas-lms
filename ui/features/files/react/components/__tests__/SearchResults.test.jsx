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
import {mount} from 'enzyme'
import {merge} from 'lodash'
import FilesCollection from '@canvas/files/backbone/collections/FilesCollection'
import Folder from '@canvas/files/backbone/models/Folder'
import SearchResults from '../SearchResults'

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
    },
    props
  )
}

describe('SearchResults', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {
      COURSE_ID: '101',
      context_asset_string: 'course_17',
    }
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  describe('accessibility message', () => {
    let wrapper

    beforeEach(() => {
      document.body.appendChild(document.createElement('div'))
    })

    afterEach(() => {
      wrapper.detach()
    })

    it('renders if userCanEditFilesForContext is true', () => {
      wrapper = mount(<SearchResults {...defaultProps()} />, {attachTo: document.body.firstChild})
      const message = document.querySelector('.SearchResults__accessbilityMessage')
      expect(message).toBeInTheDocument()
    })

    it('does not render if userCanEditFilesForContext is false', () => {
      wrapper = mount(<SearchResults {...defaultProps({userCanEditFilesForContext: false})} />, {
        attachTo: document.body.firstChild,
      })
      const message = document.querySelector('.SearchResults__accessbilityMessage')
      expect(message).toBeNull()
    })
  })

  describe('File Menu', () => {
    let wrapper, menuItems

    beforeEach(() => {
      document.body.appendChild(document.createElement('div'))
      const props = {...defaultProps()}
      const collection = new FilesCollection([
        {id: '1', created_at: '2022-01-01T00:00:00', modified_at: '2022-01-01T00:00:00'},
      ])
      wrapper = mount(<SearchResults {...props} />, {attachTo: document.body.firstChild})
      wrapper.instance().setState({collection})
      menuItems = Array.from(document.body.querySelectorAll('.al-options [role="menuitem"]'))
    })

    afterEach(() => {
      wrapper.detach()
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
        wrapper.instance().setState({sendFileId: '1'})
        expect(document.body.querySelector('[role="dialog"][aria-label="Send To..."]')).toBeTruthy()
      })
    })

    describe('Copy To item', () => {
      it('renders', () => {
        expect(menuItems.some(i => i.textContent === 'Copy To...')).toEqual(true)
      })

      it('renders a modal for sending the file, when clicked', () => {
        wrapper.instance().setState({copyFileId: '1'})
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
