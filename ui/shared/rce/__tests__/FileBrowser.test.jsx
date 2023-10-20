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
import {shallow, mount} from 'enzyme'
import React from 'react'
import FileBrowser from '../FileBrowser'

const getProps = overrides => ({
  selectFile: () => {},
  contentTypes: ['image/*'],
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

// rewrite using testing-library
describe.skip('FileBrowser', () => {
  beforeEach(() => {
    moxios.install()
    window.ENV = {context_asset_string: 'courses_1'}
  })
  afterEach(() => {
    moxios.uninstall()
    delete window.ENV
  })

  it('renders', () => {
    const wrapper = shallow(<FileBrowser {...getProps()} />)
    expect(wrapper).toMatchSnapshot()
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

    const wrapper = mount(<FileBrowser {...getProps()} />)
    const collections = {
      0: {id: 0, collections: [1]},
      1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
      4: {id: 4, name: 'folder 4', collections: [], items: [], context: '/users/1'},
    }
    wrapper.instance().setState({collections})
    wrapper.update()
    wrapper.find('TreeButton').first().simulate('click')
    moxios.wait(() => {
      wrapper.find('TreeButton').at(1).simulate('click')
      expect(wrapper.find('TreeButton')).toHaveLength(2)
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

    const wrapper = mount(<FileBrowser {...getProps()} />)
    const collections = {
      0: {id: 0, collections: [1]},
      1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
      4: {id: 4, name: 'folder 4', collections: [], items: [], context: '/users/1'},
    }
    wrapper.instance().setState({collections})
    wrapper.update()
    wrapper.find('TreeButton').first().simulate('click')
    moxios.wait(() => {
      wrapper.find('TreeButton').at(1).simulate('click')
      expect(wrapper.find('Img')).toHaveLength(1)
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

    const wrapper = shallow(<FileBrowser {...getProps()} />)
    wrapper.instance().componentDidMount()
    moxios.wait(() => {
      const node = wrapper.find('TreeBrowser')
      expect(node.props().collections[0].collections).toEqual([1, 3])
      const expected = {
        api: courseFolder(),
        collections: [2],
        items: [1],
        descriptor: null,
        id: 1,
        locked: false,
        name: 'Course files',
        canUpload: true,
        context: '/courses/1',
      }
      expect(node.props().collections[1]).toEqual(expected)
      done()
    })
    moxios.wait(() => {
      const node = wrapper.find('TreeBrowser')
      expect(node.props().collections[1].collections).toEqual([2])
      expect(node.props().collections[1].items).toEqual([1])
      expect(node.props().items[1]).toEqual({
        api: testFile(),
        id: 1,
        name: 'file 1',
        src: '/courses/1/files/1/preview',
        alt: 'file 1',
      })
      done()
    })
  })

  it('should not error when there is no context asset string', () => {
    delete window.ENV.context_asset_string
    const wrapper = shallow(<FileBrowser {...getProps()} />)
    expect(wrapper.find('TreeBrowser').exists()).toBeTruthy()
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

      const wrapper = mount(<FileBrowser {...getProps()} />)
      const collections = {
        0: {id: 0, collections: [1, 3]},
        1: {id: 1, collections: [4, 5], context: '/courses/1'},
        3: {id: 3, collections: [], items: [], context: '/courses/1'},
        4: {id: 4, collections: [], items: [], context: '/courses/1'},
        5: {id: 5, collections: [], items: [], context: '/users/1'},
      }
      wrapper.instance().setState({collections})
      wrapper.update()
      const spy = sinon.spy(wrapper.instance(), 'getFolderData')
      wrapper.find('TreeButton').first().simulate('click')
      expect(spy.called).toBeTruthy()
      moxios.wait(() => {
        const node = wrapper.find('TreeBrowser')
        expect(node.instance().props.collections[4].collections).toEqual([6])
        expect(node.instance().props.collections[5].collections).toEqual([7])
        expect(node.instance().props.collections[4].items).toEqual([1])
        expect(node.instance().props.collections[5].items).toEqual([])
        done()
      })
    })

    it('does not get new folder/file data on folder collapse', () => {
      const wrapper = mount(<FileBrowser {...getProps()} />)
      const collections = {
        0: {id: 0, collections: [1, 3]},
        1: {id: 1, collections: [4, 5], context: '/courses/1'},
        3: {id: 3, collections: [], items: [], context: '/courses/1'},
        4: {id: 4, collections: [], items: [], context: '/courses/1'},
        5: {id: 5, collections: [], items: [], context: '/users/1'},
      }
      wrapper.instance().setState({collections, openFolders: [1]})
      wrapper.update()
      const spy = sinon.spy(wrapper.instance(), 'getFolderData')
      wrapper.find('TreeButton').first().simulate('click')
      expect(spy.notCalled).toBeTruthy()
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
      const wrapper = mount(<FileBrowser {...getProps()} />)
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
        4: {id: 4, name: 'folder 4', collections: [], items: [], context: '/users/1'},
      }
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.findWhere(x => x.type() === 'button' && x.text() === 'folder 1').simulate('click')
      wrapper.findWhere(x => x.type() === 'button' && x.text() === 'folder 4').simulate('click')
      moxios.wait(() => {
        moxios.wait(() => {
          moxios.wait(() => {
            const node = wrapper.find('TreeBrowser')
            expect(node.instance().props.collections[4].collections).toEqual([6])
            expect(node.instance().props.collections[6].items).toEqual([1])
            done()
          })
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
      const wrapper = mount(<FileBrowser {...getProps()} />)
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, collections: [4], context: 'courses/1'},
        4: {id: 4, collections: [], items: [], context: 'users/1'},
      }
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.find('TreeButton').first().simulate('click')
      moxios.wait(() => {
        moxios.wait(() => {
          moxios.wait(() => {
            moxios.wait(() => {
              const node = wrapper.find('TreeBrowser')
              expect(node.instance().props.collections[4].collections).toEqual([6, 7])
              expect(node.instance().props.collections[4].items).toEqual([1, 5])
              done()
            })
          })
        })
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

      const wrapper = mount(<FileBrowser {...getProps()} />)
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
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.find('TreeButton').first().simulate('click')
      expect(wrapper.find('TreeButton span span span').last().text()).toEqual('Locked')
      moxios.wait(() => {
        const node = wrapper.find('TreeBrowser')
        expect(node.instance().props.collections[4].collections).toEqual([])
        expect(node.instance().props.collections[4].items).toEqual([])
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

      const wrapper = mount(<FileBrowser {...getProps()} />)
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [4], items: [], context: '/courses/1'},
        4: {id: 4, name: 'folder 4', collections: [5], items: [1], context: '/courses/1'},
        5: {id: 5, name: 'folder 5', collections: [], items: [], context: '/users/1'},
      }
      const items = {1: {id: 1, name: 'old name 1'}}
      wrapper.instance().setState({collections, items})
      wrapper.update()
      wrapper.find('TreeButton').first().simulate('click')
      moxios.wait(() => {
        const node = wrapper.find('TreeBrowser')
        expect(node.instance().props.collections[5].name).toEqual('sub folder 1')
        expect(node.instance().props.collections[4].items).toEqual([1, 2])
        expect(node.instance().props.items[1].name).toEqual('file 1')
        done()
      })
    })
  })

  describe('on file click', () => {
    it('sets a selected file on file click', () => {
      const spy = sinon.spy()
      const wrapper = mount(<FileBrowser {...getProps({selectFile: spy})} />)
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [], items: [1, 2]},
      }
      const items = {
        1: {id: 1, name: 'file 1', alt: 'file 1', src: '/courses/1/files/1/preview'},
        2: {id: 2, name: 'file 2', alt: 'file 2', src: '/courses/1/files/2/preview'},
      }
      wrapper.instance().setState({collections, items})
      wrapper.update()
      wrapper.find('TreeButton').first().simulate('click')
      wrapper.find('TreeButton').at(1).simulate('click')
      expect(spy.getCall(0).args[0]).toEqual(items[1])
      wrapper.find('TreeButton').at(2).simulate('click')
      expect(spy.getCall(1).args[0]).toEqual(items[2])
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

      const wrapper = mount(<FileBrowser {...getProps()} />)
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [], items: [], context: '/courses/1'},
      }
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.instance().getFolderData(1)
      wrapper.update()
      moxios.wait(() => {
        const node = wrapper.find('TreeBrowser').first()
        expect(node.instance().props.collections[1].collections).toEqual([5, 7, 6])
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

      const wrapper = mount(<FileBrowser {...getProps()} />)
      const collections = {
        0: {id: 0, collections: [1]},
        1: {id: 1, name: 'folder 1', collections: [], items: [], context: '/courses/1'},
      }
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.instance().getFolderData(1)
      wrapper.update()
      moxios.wait(() => {
        const node = wrapper.find('TreeBrowser').first()
        expect(node.instance().props.collections[1].items).toEqual([1, 3, 2])
        done()
      })
    })
  })

  describe('upload dialog', () => {
    it('does not show upload button if disallowed', () => {
      const wrapper = shallow(<FileBrowser {...getProps({allowUpload: false})} />)
      expect(wrapper.instance().renderUploadDialog()).toBe(null)
    })

    it('activates upload button for folders user can upload to', () => {
      const wrapper = mount(<FileBrowser {...getProps()} />)
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
      wrapper.instance().setState({collections})
      wrapper.update()
      expect(wrapper.find('#image-upload__upload button').prop('disabled')).toBe(true)
      wrapper.find('TreeButton').at(0).simulate('click')
      expect(wrapper.find('#image-upload__upload button').prop('disabled')).toBe(false)
      wrapper.find('TreeButton').at(1).simulate('click')
      expect(wrapper.find('#image-upload__upload button').prop('disabled')).toBe(true)
      wrapper.find('TreeButton').at(2).simulate('click')
      expect(wrapper.find('#image-upload__upload button').prop('disabled')).toBe(true)
    })

    it('uploads a file', () => {
      const wrapper = mount(<FileBrowser {...getProps()} />)
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
      const spy = sinon.spy(wrapper.instance(), 'submitFile')
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.find('TreeButton').at(0).simulate('click')
      wrapper.find('input').simulate('change', {
        target: {
          files: ['dummyValue.png'],
        },
      })
      expect(spy.called).toBeTruthy()
    })

    it('allows uploads without folder selection when a default folder is provided', () => {
      const overrides = {defaultUploadFolderId: courseFolder().id.toString()}
      const wrapper = mount(<FileBrowser {...getProps(overrides)} />)
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
      wrapper.instance().setState({collections})
      wrapper.update()
      expect(wrapper.find('#image-upload__upload button').prop('disabled')).toBe(false)
    })

    it('renders a spinner while uploading files', () => {
      const wrapper = mount(<FileBrowser {...getProps()} />)
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
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.find('TreeButton').at(0).simulate('click')
      wrapper.find('input').simulate('change', {
        target: {
          files: ['dummyValue.png'],
        },
      })
      expect(wrapper.find('Mask').exists()).toBeTruthy()
      expect(wrapper.find('Spinner').exists()).toBeTruthy()
    })

    it('shows an alert on file upload', done => {
      const wrapper = mount(<FileBrowser {...getProps()} />)
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
      wrapper.instance().setState({collections})
      wrapper.update()
      const spy = sinon.spy(wrapper.instance(), 'setSuccessMessage')
      moxios.stubRequest('/api/v1/folders/1/files', {
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
      wrapper.find('TreeButton').first().simulate('click')
      wrapper.find('input').simulate('change', {
        target: {
          files: [{name: 'file 1', size: 0}],
        },
      })
      moxios.wait(() => {
        moxios.wait(() => {
          wrapper.update()
          expect(spy.calledOnce).toBeTruthy()
          expect(spy.calledWith('Success: File uploaded')).toBeTruthy()
          const button = wrapper.find('TreeButton').at(0)
          expect(button.text()).toEqual('folder 1')
          done()
        })
      })
    })

    it('shows an alert on file upload fail', done => {
      const wrapper = mount(<FileBrowser {...getProps()} />)
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
      const spy = sinon.spy(wrapper.instance(), 'setFailureMessage')
      moxios.stubRequest('/api/v1/folders/1/files', {
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
      wrapper.instance().setState({collections})
      wrapper.update()
      wrapper.find('TreeButton').first().simulate('click')
      wrapper
        .find('input')
        .first()
        .simulate('change', {
          target: {
            files: [{name: 'file 1', size: 0}],
          },
        })
      moxios.wait(() => {
        expect(spy.calledOnce).toBeTruthy()
        expect(spy.calledWith('File upload failed')).toBeTruthy()
        done()
      })
    })
  })

  describe('FileBrowser content type filtering', () => {
    it('allows all content types by default', () => {
      const no_type_param = {selectFile: () => {}}
      const wrapper = shallow(<FileBrowser {...no_type_param} />)
      expect(wrapper.instance().contentTypeIsAllowed('image/png')).toBeTruthy()
      expect(wrapper.instance().contentTypeIsAllowed('some/not-real-thing')).toBeTruthy()
    })

    it('can restrict to one content type pattern', () => {
      const wrapper = shallow(<FileBrowser {...getProps({contentTypes: ['image/*']})} />)
      expect(wrapper.instance().contentTypeIsAllowed('image/png')).toBeTruthy()
      expect(wrapper.instance().contentTypeIsAllowed('image/jpeg')).toBeTruthy()
      expect(wrapper.instance().contentTypeIsAllowed('video/mp4')).toBeFalsy()
      expect(wrapper.instance().contentTypeIsAllowed('not/allowed')).toBeFalsy()
    })

    it('can restrict to multiple content type patterns', () => {
      const wrapper = shallow(<FileBrowser {...getProps({contentTypes: ['image/*', 'video/*']})} />)
      expect(wrapper.instance().contentTypeIsAllowed('image/png')).toBeTruthy()
      expect(wrapper.instance().contentTypeIsAllowed('image/jpeg')).toBeTruthy()
      expect(wrapper.instance().contentTypeIsAllowed('video/mp4')).toBeTruthy()
      expect(wrapper.instance().contentTypeIsAllowed('not/allowed')).toBeFalsy()
    })
  })
})
