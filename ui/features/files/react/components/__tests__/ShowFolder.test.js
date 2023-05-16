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
import {render} from '@testing-library/react'
import ShowFolder from '../ShowFolder'
import sinon from 'sinon'
import FilesCollection from '@canvas/files/backbone/collections/FilesCollection'
import Folder from '@canvas/files/backbone/models/Folder'
import {merge} from 'lodash'

const defaultProps = (props = {}) => {
  const ref = document.createElement('div')
  const folder = new Folder()
  folder.files.loadedAll = true
  folder.folders.loadedAll = true

  return merge(
    {
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
    },
    props
  )
}

describe('ShowFolder', () => {
  let oldEnv, sandbox

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {
      COURSE_ID: '101',
      context_asset_string: 'course_17',
    }
    sandbox = sinon.createSandbox()
    sandbox.stub(Folder, 'resolvePath').returns(new Promise(() => {}))
  })

  afterEach(() => {
    sandbox.restore()
    window.ENV = oldEnv
  })

  it('renders the accessibility message if userCanEditFilesForContext is true', () => {
    const {getByText} = render(<ShowFolder {...defaultProps()} />)
    expect(getByText(/Warning/)).toBeInTheDocument()
  })
  it('does not render the accessibility message if userCanEditFilesForContext is false', () => {
    const props = defaultProps({userCanEditFilesForContext: false})
    const {queryByText} = render(<ShowFolder {...props} />)
    expect(queryByText(/Warning/)).not.toBeInTheDocument()
  })

  it('renders the FileUpload component if userCanAddFilesForContext is true', () => {
    const {getByText} = render(<ShowFolder {...defaultProps()} />)
    expect(getByText('Drop files here to upload')).toBeInTheDocument()
  })

  it('does not render the FileUpload component if userCanAddFilesForContext is false', () => {
    const props = defaultProps({userCanAddFilesForContext: false})
    const {queryByText} = render(<ShowFolder {...props} />)
    expect(queryByText('Drop files here to upload')).not.toBeInTheDocument()
  })

  it('renders empty text if the folder is empty', () => {
    const props = defaultProps()
    sandbox.stub(props.currentFolder, 'isEmpty').returns(true)
    const {getByText} = render(<ShowFolder {...props} />)
    expect(getByText('This folder is empty')).toBeInTheDocument()
  })

  it('does not render empty text if the folder isnt empty', () => {
    const props = defaultProps()
    sandbox.stub(props.currentFolder, 'isEmpty').returns(false)
    const {queryByText} = render(<ShowFolder {...props} />)
    expect(queryByText('This folder is empty')).not.toBeInTheDocument()
  })

  describe('Send To file menu item', () => {
    test('renders a modal for sending the file, when clicked', () => {
      const props = {...defaultProps()}
      props.currentFolder.files = new FilesCollection([
        {id: '1', created_at: '2022-01-01T00:00:00', modified_at: '2022-01-01T00:00:00'},
      ])
      props.currentFolder.files.loadedAll = true
      const {queryByRole} = render(<ShowFolder {...props} />)
      queryByRole('menuitem', {hidden: true, name: 'Send To...'}).click()
      expect(queryByRole('dialog', {name: 'Send To...'})).toBeInTheDocument()
    })
  })

  describe('Copy To file menu item', () => {
    test('renders a modal for sending the file, when clicked', async () => {
      const props = {...defaultProps()}
      props.currentFolder.files = new FilesCollection([
        {id: '1', created_at: '2022-01-01T00:00:00', modified_at: '2022-01-01T00:00:00'},
      ])
      props.currentFolder.files.loadedAll = true
      const {queryByRole} = render(<ShowFolder {...props} />)
      queryByRole('menuitem', {hidden: true, name: 'Copy To...'}).click()
      expect(queryByRole('dialog', {name: 'Copy To...'})).toBeInTheDocument()
    })
  })
})
