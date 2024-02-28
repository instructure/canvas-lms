/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ModuleFileDrop from '../index'

jest.mock('../apiClient', () => {
  const originalModule = jest.requireActual('../apiClient')
  return {
    ...originalModule,
    getCourseRootFolder: jest
      .fn()
      .mockImplementation(() => Promise.resolve({context_id: '1', context_type: 'Course'})),
    getFolderFiles: jest.fn().mockImplementation(() => Promise.resolve(['a.txt'])),
  }
})

let component

const props = {
  courseId: '1',
  moduleId: '1',
}

beforeEach(() => {
  ModuleFileDrop.folderState = {}
  jest.spyOn(ModuleFileDrop.prototype, 'fetchRootFolder').mockImplementation()
})

afterEach(() => {
  if (component.exists()) {
    component.unmount()
  }
  jest.restoreAllMocks()
})

it('fetchRootFolder sets folderState ', done => {
  component = mount(<ModuleFileDrop {...props} />)
  jest.restoreAllMocks()

  component
    .instance()
    .fetchRootFolder()
    .then(() => {
      expect(ModuleFileDrop.folderState).toEqual({
        contextId: '1',
        contextType: 'Course',
        folder: {
          context_id: '1',
          context_type: 'Course',
          files: ['a.txt'],
        },
      })
      done() // eslint-disable-line promise/no-callback-in-promise
    })
    .catch(() => done.fail())
})

it('registers and deregisters drop components', () => {
  component = mount(<ModuleFileDrop {...props} />)
  expect(ModuleFileDrop.activeDrops.size).toEqual(1)
  component.unmount()
  expect(ModuleFileDrop.activeDrops.size).toEqual(0)
})

it('renders disabled file drop with loading billboard', () => {
  component = mount(<ModuleFileDrop {...props} />)
  expect(component.find('FileDrop').first().props().interaction).toEqual('disabled')
  expect(component.find('Billboard').first().text()).toEqual('Loading...')
})

it('renders enabled file drop with active billboard', () => {
  component = mount(<ModuleFileDrop {...props} />)
  component.find(ModuleFileDrop).setState({folder: {files: []}}, () => {
    expect(component.find('FileDrop').first().props().interaction).toEqual('enabled')
    const billboard = component.find('Billboard').first()
    expect(billboard.text()).toContain('Drop files here to add to module')
    expect(billboard.text()).toContain('or choose files')
  })
})

it('renders invisible upload form when files are dropped', () => {
  component = mount(<ModuleFileDrop {...props} />)
  component.setState(
    {folder: {files: []}, isUploading: true, contextId: '1', contextType: 'Course'},
    () => {
      const uploadForm = component.find('UploadForm')
      expect(uploadForm.exists()).toEqual(true)
      expect(uploadForm.props().visible).toEqual(false)
      expect(uploadForm.props().alwaysUploadZips).toEqual(true)
      expect(component.find('CurrentUploads').exists()).toEqual(true)
    }
  )
})
