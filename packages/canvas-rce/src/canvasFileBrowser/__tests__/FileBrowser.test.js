/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import FileBrowser from '../FileBrowser'

jest.mock('../natcompare', () => ({strings: a => a}))

// TODO: remove mock once files are fetched via RCS
jest.mock('axios', () => ({get: () => Promise.resolve({ headers: {}, data: []})}))

const folderFor = (context, overrides, bookmark) => ({
  folders: [
    {
      id: 26,
      parentId: null,
      name: `${context.type} files`,
      filesUrl: 'http://rce.canvas.docker/api/files/26',
      foldersUrl: 'http://rce.canvas.docker/api/folders/26',
      lockedForUser: false,
      contextType: context.type,
      contextId: context.id,
      canUpload: true,
      ...overrides
    }
  ],
  bookmark
})

const defaultProps = overrides => ({
  allowedUpload: true,
  selectFile: jest.fn(),
  contentTypes: [],
  useContextAssets: false,
  searchString: '',
  onLoading: jest.fn(),
  context: {
    type: 'course',
    id: 1
  },
  source: {
    fetchRootFolder: jest.fn().mockImplementation(({contextType}) => {
      if (contextType === 'course') {
        return Promise.resolve(folderFor({type: 'course', id: 1}, {id: 26}))
      } else {
        return Promise.resolve(folderFor({type: 'user', id: 2}, {id: 277}))
      }
    }),
    fetchSubFolders: jest.fn().mockResolvedValue(),
    fetchBookmarkedData: jest.fn().mockImplementation(() => {
      return Promise.resolve(folderFor({type: 'course', id: 1}), {parentId: 26})
    })
  },
  ...overrides
})

const subject = props => render(<FileBrowser {...props} />)

describe('FileBrowser', () => {
  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('componentDidMount()', () => {
    let props

    beforeEach(() => (props = defaultProps()))

    it('does not fetch the context root folder', async () => {
      const {queryByText} = subject(props)
      const folder = await waitFor(() => queryByText('Course files'))
      expect(folder).not.toBeInTheDocument()
    })

    it('fetches and renders the user root folder', async () => {
      const {getByText} = subject(props)
      const folder = await waitFor(() => getByText('My files'))
      expect(folder).toBeInTheDocument()
    })

    it('fetches root folder data', async () => {
      const {getByText} = subject(props)
      await waitFor(() => getByText('My files'))
      expect(props.source.fetchBookmarkedData).toHaveBeenCalled()
    })

    describe('when "useContextAssets" is true', () => {
      beforeEach(() => (props = defaultProps({useContextAssets: true})))

      it('fetches and renders the context root folder', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('Course files'))
        expect(folder).toBeInTheDocument()
      })

      it('fetches and renders the user root folder', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))
        expect(folder).toBeInTheDocument()
      })
    })
  })
})
