// Copyright (C) 2017 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import moxios from 'moxios'
import sinon from 'sinon'
import {render, cleanup, fireEvent} from '@testing-library/react'
import {userEvent} from '@testing-library/user-event'
import React from 'react'
import FileBrowser from '../FileBrowser'

const getProps = overrides => ({
  selectFile: () => {},
  useContextAssets: true,
  ...overrides,
})

const courseFolder = overrides => ({
  id: 1,
  name: 'course files',
  context_id: 1,
  context_type: 'course',
  can_upload: true,
  locked_for_user: false,
  parent_folder_id: null,
  ...overrides,
})

const userFolder = overrides => ({
  id: 3,
  name: 'my files',
  context_id: 2,
  context_type: 'user',
  parent_folder_id: null,
  can_upload: true,
  ...overrides,
})

const testFile = overrides => ({
  id: 1,
  display_name: 'file 1',
  folder_id: 1,
  'content-type': 'image/jpg',
  ...overrides,
})

const getClosestElementByType = (wrapper, text, type) => wrapper.getByText(text).closest(type)

const getNthOfElementByType = (wrapper, index, type) =>
  wrapper.container.querySelectorAll(type)[index]

const renderFileBrowser = props => {
  const ref = React.createRef()
  const activeProps = {
    ...getProps(),
    ...props,
    ref,
  }
  const wrapper = render(<FileBrowser {...activeProps} />)

  return {
    wrapper,
    ref,
  }
}

// rewrite using testing-library
describe('FileBrowser', () => {
  beforeEach(() => {
    moxios.install()
    window.ENV = {context_asset_string: 'courses_1'}
  })

  afterEach(() => {
    cleanup()
    moxios.uninstall()
    delete window.ENV
  })

  it('renders', () => {
    const {wrapper} = renderFileBrowser()

    expect(wrapper.container).toBeInTheDocument()
  })

  it('only shows images in the tree', done => {
    const files = [
      testFile({folder_id: 4, thumbnail_url: 'thumbnail.jpg'}),
      testFile({
        id: 2,
        display_name: 'file 2',
        folder_id: 4,
        thumbnail_url: 'thumbnail.jpg',
        'content-type': 'text/html',
      }),
    ]
    moxios.stubRequest('/api/v1/folders/4/files', {
      status: 200,
      responseText: files,
      headers: {link: 'url; rel="current"'},
    })

    const {wrapper, ref} = renderFileBrowser()
    const folder1 = 'folder 1'
    const folder4 = 'folder 4'
    const collections = {
      0: {id: 0, collections: [1]},
      1: {id: 1, name: folder1, collections: [4], items: [], context: '/courses/1'},
      4: {id: 4, name: folder4, collections: [], items: [], context: '/users/1'},
    }
    ref.current.setState({collections})

    userEvent.click(getClosestElementByType(wrapper, folder1, 'button'))

    moxios.wait(() => {
      userEvent.click(getClosestElementByType(wrapper, folder4, 'button'))

      expect(wrapper.container.querySelectorAll('button')).toHaveLength(3)
      done()
    })
  })

  it('shows thumbnails if provided', done => {
    const files = [testFile({folder_id: 4, thumbnail_url: 'thumbnail.jpg'})]
    moxios.stubRequest('/api/v1/folders/4/files', {
      status: 200,
      responseText: files,
      headers: {link: 'url; rel="current"'},
    })

    const {wrapper, ref} = renderFileBrowser()
    const collections = {
      0: {id: 0, collections: [1]},
      1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
      4: {id: 4, name: 'folder 4', collections: [], items: [], context: '/users/1'},
    }
    ref.current.setState({collections})

    userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))

    moxios.wait(async () => {
      await userEvent.click(getNthOfElementByType(wrapper, 1, 'button'))
      expect(wrapper.container.querySelector('img')).toBeInTheDocument()
      done()
    })
  })

  it('gets root folder data on mount', done => {
    moxios.stubRequest('/api/v1/courses/1/folders/root', {
      status: 200,
      responseText: courseFolder(),
      headers: {link: 'url; rel="current"'},
    })
    moxios.stubRequest('/api/v1/users/self/folders/root', {
      status: 200,
      responseText: userFolder(),
      headers: {link: 'url; rel="current"'},
    })
    const subFolders = [userFolder({id: 2, name: 'sub folder 1', parent_folder_id: 1})]
    const files = [testFile()]
    moxios.stubRequest('/api/v1/folders/1/folders', {
      status: 200,
      responseText: subFolders,
      headers: {link: 'url; rel="current"'},
    })
    moxios.stubRequest('/api/v1/folders/1/files', {
      status: 200,
      responseText: files,
      headers: {link: 'url; rel="current"'},
    })

    const {wrapper} = renderFileBrowser()

    moxios.wait(() => {
      expect(wrapper.getByText('Course files')).toBeInTheDocument()
      expect(wrapper.getByText('My files')).toBeInTheDocument()
      done()
    })
  })

  it('should not error when there is no context asset string', () => {
    delete window.ENV.context_asset_string
    const {wrapper} = renderFileBrowser()

    expect(wrapper.container).toBeInTheDocument()
  })

  describe('on folder click', () => {
    it("gets sub-folders and files for folder's sub-folders on folder expand", done => {
      const subFolders1 = [courseFolder({id: 6, name: 'sub folder 1', parent_folder_id: 4})]
      const subFolders2 = [courseFolder({id: 7, name: 'sub folder 2', parent_folder_id: 5})]
      const files1 = [testFile({folder_id: 4})]
      const files2 = []

      moxios.stubRequest('/api/v1/folders/4/folders', {
        status: 200,
        responseText: subFolders1,
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/5/folders', {
        status: 200,
        responseText: subFolders2,
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/4/files', {
        status: 200,
        responseText: files1,
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/5/files', {
        status: 200,
        responseText: files2,
        headers: {link: 'url; rel="current"'},
      })

      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1, 3]},
        1: {id: 1, collections: [4, 5], context: '/courses/1'},
        3: {id: 3, collections: [], items: [], context: '/courses/1'},
        4: {id: 4, collections: [], items: [], context: '/courses/1'},
        5: {id: 5, collections: [], items: [], context: '/users/1'},
      }

      ref.current.setState({collections})
      jest.spyOn(ref.current, 'getFolderData')

      userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))

      moxios.wait(() => {
        expect(ref.current.state.collections[4].collections).toEqual([6])
        expect(ref.current.state.collections[5].collections).toEqual([7])
        expect(ref.current.state.collections[4].items).toEqual([1])
        expect(ref.current.state.collections[5].items).toEqual([])
        done()
      })
    })

    it('does not get new folder/file data on folder collapse', async () => {
      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1, 3]},
        1: {id: 1, collections: [4, 5], context: '/courses/1'},
        3: {id: 3, collections: [], items: [], context: '/courses/1'},
        4: {id: 4, collections: [], items: [], context: '/courses/1'},
        5: {id: 5, collections: [], items: [], context: '/users/1'},
      }

      ref.current.setState({collections, openFolders: [1]})

      jest.spyOn(ref.current, 'getFolderData')

      await userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))

      expect(ref.current.getFolderData).not.toHaveBeenCalled()
    })

    it('populates data for items that were not loaded yet when the parent folder was clicked', done => {
      const subFolders = [courseFolder({id: 6, name: 'sub folder 1', parent_folder_id: 4})]
      const files = [testFile({folder_id: 6})]

      moxios.stubRequest('/api/v1/folders/4/folders', {
        status: 200,
        responseText: subFolders,
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/6/folders', {
        status: 200,
        responseText: [],
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/6/files', {
        status: 200,
        responseText: files,
        headers: {link: 'url; rel="current"'},
      })

      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
        4: {id: 4, name: 'folder 4', collections: [], items: [], context: '/users/1'},
      }

      ref.current.setState({collections})

      userEvent.click(getClosestElementByType(wrapper, 'folder 1', 'button')).then(async () => {
        await userEvent.click(getClosestElementByType(wrapper, 'folder 4', 'button'))

        moxios.wait(() => {
          expect(ref.current.state.collections[4].collections).toEqual([6])
          expect(ref.current.state.collections[6].items).toEqual([1])
          done()
        })
      })
    })

    it('gets additional pages of data', done => {
      const subFolders1 = [courseFolder({id: 6, name: 'sub folder 1', parent_folder_id: 4})]
      const subFolders2 = [courseFolder({id: 7, name: 'sub folder 2', parent_folder_id: 4})]
      const files1 = [testFile({folder_id: 4})]
      const files2 = [testFile({id: 5, display_name: 'file 5', folder_id: 4})]
      moxios.stubRequest('/api/v1/folders/4/folders', {
        status: 200,
        responseText: subFolders1,
        headers: {link: '</api/v1/folders/4/folders?page=2>; rel="next"'},
      })
      moxios.stubRequest('/api/v1/folders/4/folders?page=2', {
        status: 200,
        responseText: subFolders2,
        headers: {link: '<url>; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/4/files', {
        status: 200,
        responseText: files1,
        headers: {link: '</api/v1/folders/4/files?page=2>; rel="next"'},
      })
      moxios.stubRequest('/api/v1/folders/4/files?page=2', {
        status: 200,
        responseText: files2,
        headers: {link: '<url>; rel="current"'},
      })

      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, collections: [4], context: 'courses/1'},
        4: {id: 4, collections: [], items: [], context: 'users/1'},
      }

      ref.current.setState({collections})

      userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))

      moxios.wait(() => {
        expect(ref.current.state.collections[4].collections).toEqual([6, 7])
        expect(ref.current.state.collections[4].items).toEqual([1, 5])
        done()
      })
    })

    it('does not get data for locked sub-folders', done => {
      const subFolders = [courseFolder({id: 6, name: 'sub folder 1', parent_folder_id: 4})]
      const files = [testFile({folder_id: 4})]
      moxios.stubRequest('/api/v1/folders/4/folders', {
        status: 401,
        responseText: subFolders,
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/4/files', {
        status: 401,
        responseText: files,
        headers: {link: 'url; rel="current"'},
      })

      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
        4: {
          id: 4,
          name: 'folder 4',
          collections: [],
          items: [],
          descriptor: 'Locked',
          locked: true,
          context: '/users/1',
        },
      }

      ref.current.setState({collections})

      userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))

      moxios.wait(() => {
        expect(wrapper.getByText('Locked')).toBeInTheDocument()
        expect(ref.current.state.collections[4].collections).toEqual([])
        expect(ref.current.state.collections[4].items).toEqual([])
        done()
      })
    })

    it('replaces folder and file data if the folder has previously been loaded', done => {
      const subFolders = [courseFolder({id: 5, name: 'sub folder 1', parent_folder_id: 4})]
      const files = [
        testFile({folder_id: 4}),
        testFile({id: 2, display_name: 'file 2', folder_id: 4}),
      ]
      moxios.stubRequest('/api/v1/folders/4/folders', {
        status: 200,
        responseText: subFolders,
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/4/files', {
        status: 200,
        responseText: files,
        headers: {link: 'url; rel="current"'},
      })

      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
        4: {id: 4, name: 'folder 4', collections: [5], items: [1], context: '/courses/1'},
        5: {id: 5, name: 'folder 5', collections: [], items: [], context: '/users/1'},
      }
      const items = {1: {id: 1, name: 'old name 1'}}

      ref.current.setState({collections, items})

      userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))

      moxios.wait(() => {
        expect(ref.current.state.collections[5].name).toEqual('sub folder 1')
        expect(ref.current.state.collections[4].items).toEqual([1, 2])
        expect(ref.current.state.items[1].name).toEqual('file 1')
        done()
      })
    })
  })

  describe('on file click', () => {
    it('sets a selected file on file click', async () => {
      const spy = jest.fn()
      const {wrapper, ref} = renderFileBrowser({selectFile: spy})
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [], items: [1, 2]},
      }
      const items = {
        1: {id: 1, name: 'file 1', alt: 'file 1', src: '/courses/1/files/1/preview'},
        2: {id: 2, name: 'file 2', alt: 'file 2', src: '/courses/1/files/2/preview'},
      }
      ref.current.setState({collections, items})

      await userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))
      await userEvent.click(getNthOfElementByType(wrapper, 1, 'button'))

      expect(spy).toHaveBeenCalledWith(items[1])

      await userEvent.click(getNthOfElementByType(wrapper, 2, 'button'))

      expect(spy).toHaveBeenCalledWith(items[2])
    })
  })

  describe('ordering', () => {
    it('orders collections naturally by folder name', done => {
      const subFolders = [
        courseFolder({id: 5, name: 'sub folder 1', parent_folder_id: 1}),
        courseFolder({id: 6, name: 'sub folder 10', parent_folder_id: 1}),
        courseFolder({id: 7, name: 'sub folder 2', parent_folder_id: 1}),
      ]

      moxios.stubRequest('/api/v1/folders/1/folders', {
        status: 200,
        responseText: subFolders,
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/1/files', {
        status: 200,
        responseText: [],
        headers: {link: 'url; rel="current"'},
      })

      const {ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [], items: [], context: '/courses/1'},
      }

      ref.current.setState({collections})
      ref.current.getFolderData(1)

      moxios.wait(() => {
        expect(ref.current.state.collections[1].collections).toEqual([5, 7, 6])
        done()
      })
    })

    it('orders items naturally by file name', done => {
      const files = [
        testFile({id: 1, display_name: 'file 1', folder_id: 1}),
        testFile({id: 2, display_name: 'file 10', folder_id: 1}),
        testFile({id: 3, display_name: 'file 2', folder_id: 1}),
      ]
      moxios.stubRequest('/api/v1/folders/1/folders', {
        status: 200,
        responseText: [],
        headers: {link: 'url; rel="current"'},
      })
      moxios.stubRequest('/api/v1/folders/1/files', {
        status: 200,
        responseText: files,
        headers: {link: 'url; rel="current"'},
      })

      const {ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [], items: [], context: '/courses/1'},
      }

      ref.current.setState({collections})
      ref.current.getFolderData(1)

      moxios.wait(() => {
        expect(ref.current.state.collections[1].items).toEqual([1, 3, 2])
        done()
      })
    })
  })

  describe('upload dialog', () => {
    it('does not show upload button if disallowed', () => {
      const {ref} = renderFileBrowser({allowUpload: false})

      expect(ref.current.renderUploadDialog()).toBeNull()
    })

    it('activates upload button for folders user can upload to', async () => {
      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {
          id: 1,
          name: 'folder 1',
          collections: [4, 5],
          items: [],
          canUpload: true,
          locked: false,
          context: '/courses/1',
        },
        4: {
          id: 4,
          name: 'folder 4',
          collections: [],
          items: [],
          canUpload: false,
          locked: false,
          context: '/courses/1',
        },
        5: {
          id: 5,
          name: 'folder 5',
          collections: [],
          items: [],
          canUpload: true,
          locked: true,
          context: '/users/1',
        },
      }
      ref.current.setState({collections})

      expect(
        wrapper.container.querySelector('button#image-upload__upload[disabled]')
      ).toBeInTheDocument()
      await userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))
      expect(
        wrapper.container.querySelector('button#image-upload__upload[disabled]')
      ).not.toBeInTheDocument()
      await userEvent.click(getNthOfElementByType(wrapper, 1, 'button'))
      expect(
        wrapper.container.querySelector('button#image-upload__upload[disabled]')
      ).toBeInTheDocument()
      await userEvent.click(getNthOfElementByType(wrapper, 2, 'button'))
      expect(
        wrapper.container.querySelector('button#image-upload__upload[disabled]')
      ).toBeInTheDocument()
    })

    it('uploads a file', async () => {
      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {
          id: 1,
          name: 'folder 1',
          collections: [],
          items: [],
          canUpload: true,
          locked: false,
          context: '/courses/1',
        },
      }
      const spy = sinon.spy(ref.current, 'submitFile')

      ref.current.setState({collections})

      await userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))
      fireEvent.change(wrapper.container.querySelector('input'), {
        target: {
          files: ['dummyValue.png'],
        },
      })
      expect(spy.called).toBeTruthy()
    })

    it('allows uploads without folder selection when a default folder is provided', () => {
      const overrides = {defaultUploadFolderId: courseFolder().id.toString()}
      const {wrapper, ref} = renderFileBrowser(overrides)
      const collections = {
        0: {id: 0, collections: [1]},
        1: {
          id: 1,
          name: 'folder 1',
          collections: [],
          items: [],
          canUpload: true,
          locked: false,
          context: '/courses/1',
        },
      }

      ref.current.setState({collections})

      expect(
        wrapper.container.querySelector('button#image-upload__upload[disabled]')
      ).not.toBeInTheDocument()
    })

    it('renders a spinner while uploading files', async () => {
      const {wrapper, ref} = renderFileBrowser()
      const collections = {
        0: {id: 0, collections: [1]},
        1: {
          id: 1,
          name: 'folder 1',
          collections: [],
          items: [],
          canUpload: true,
          locked: false,
          context: '/courses/1',
        },
      }
      ref.current.setState({collections})

      await userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))
      fireEvent.change(wrapper.container.querySelector('input'), {
        target: {
          files: ['dummyValue.png'],
        },
      })

      expect(wrapper.getByText('File uploading')).toBeInTheDocument()
    })

    it('shows an alert on file upload', done => {
      const id = '1'
      const {wrapper, ref} = renderFileBrowser({
        defaultUploadFolderId: id,
      })
      const collections = {
        0: {id: 0, collections: [1]},
        [id]: {
          id,
          name: 'folder 1',
          collections: [],
          items: [],
          canUpload: true,
          locked: false,
          context: '/courses/1',
        },
      }

      ref.current.setState({collections})
      jest.spyOn(ref.current, 'setSuccessMessage')
      moxios.stubRequest(`/api/v1/folders/${id}/files`, {
        status: 200,
        response: {
          upload_url: 'http://new_url',
          upload_params: {
            Filename: 'file',
            key: 'folder/filename',
            'content-type': 'image/png',
          },
          file_param: 'attachment[uploaded_data]',
        },
      })
      moxios.stubRequest('http://new_url', {
        status: 200,
        response: {id: 1, display_name: 'file 1', 'content-type': 'image/png', folder_id: 1},
      })

      userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))
      fireEvent.change(wrapper.container.querySelector('input'), {
        target: {
          files: [{name: 'file 1', size: 0}],
        },
      })

      moxios.wait(() => {
        expect(ref.current.setSuccessMessage).toHaveBeenCalled()
        expect(ref.current.setSuccessMessage).toHaveBeenCalledWith('Success: File uploaded')
        expect(wrapper.getByText('folder 1')).toBeInTheDocument()

        done()
      })
    })

    it('shows an alert on file upload fail', done => {
      const id = '1'
      const {wrapper, ref} = renderFileBrowser({
        defaultUploadFolderId: id,
      })
      const collections = {
        0: {id: 0, collections: [1]},
        [id]: {
          id,
          name: 'folder 1',
          collections: [],
          items: [],
          canUpload: true,
          locked: false,
          context: '/courses/1',
        },
      }

      jest.spyOn(ref.current, 'setFailureMessage')
      moxios.stubRequest(`/api/v1/folders/${id}/files`, {
        status: 500,
        response: {
          upload_url: 'http://new_url',
          upload_params: {
            Filename: 'file',
            key: 'folder/filename',
            'content-type': 'image/png',
          },
          file_param: 'attachment[uploaded_data]',
        },
      })
      ref.current.setState({
        collections,
      })

      userEvent.click(getNthOfElementByType(wrapper, 0, 'button'))
      fireEvent.change(wrapper.container.querySelector('input'), {
        target: {
          files: [{name: 'file 1', size: 0}],
        },
      })

      moxios.wait(() => {
        expect(ref.current.setFailureMessage).toHaveBeenCalled()
        expect(ref.current.setFailureMessage).toHaveBeenCalledWith('File upload failed')
        done()
      })
    })
  })

  describe('FileBrowser content type filtering', () => {
    it('allows all content types by default', () => {
      const no_type_param = {selectFile: () => {}}
      const {ref} = renderFileBrowser(no_type_param)

      expect(ref.current.contentTypeIsAllowed('image/png')).toBeTruthy()
      expect(ref.current.contentTypeIsAllowed('some/not-real-thing')).toBeTruthy()
    })

    it('can restrict to one content type pattern', () => {
      const {ref} = renderFileBrowser({contentTypes: ['image/*']})

      expect(ref.current.contentTypeIsAllowed('image/png')).toBeTruthy()
      expect(ref.current.contentTypeIsAllowed('image/jpeg')).toBeTruthy()
      expect(ref.current.contentTypeIsAllowed('video/mp4')).toBeFalsy()
      expect(ref.current.contentTypeIsAllowed('not/allowed')).toBeFalsy()
    })

    it('can restrict to multiple content type patterns', () => {
      const {ref} = renderFileBrowser({contentTypes: ['image/*', 'video/*']})

      expect(ref.current.contentTypeIsAllowed('image/png')).toBeTruthy()
      expect(ref.current.contentTypeIsAllowed('image/jpeg')).toBeTruthy()
      expect(ref.current.contentTypeIsAllowed('video/mp4')).toBeTruthy()
      expect(ref.current.contentTypeIsAllowed('not/allowed')).toBeFalsy()
    })
  })
})
