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
import ModuleFileDrop from '../index'
import {cleanup, render} from '@testing-library/react'

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
  jest.restoreAllMocks()
})

it('fetchRootFolder sets folderState ', done => {
  const ref = React.createRef()
  component = render(<ModuleFileDrop {...props} ref={ref} />)
  jest.restoreAllMocks()

  ref.current
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
  component = render(<ModuleFileDrop {...props} />)
  expect(ModuleFileDrop.activeDrops.size).toEqual(1)
  cleanup()
  expect(ModuleFileDrop.activeDrops.size).toEqual(0)
})

it('renders disabled file drop with loading billboard', () => {
  const ref = React.createRef()
  component = render(<ModuleFileDrop {...props} ref={ref} />)
  expect(ref.current.state.interaction).toBeTruthy()
  expect(ref.current.state.folder).toBeFalsy()
  expect(component.queryByText('Loading...')).toBeInTheDocument()
})

it('renders enabled file drop with active billboard', () => {
  const ref = React.createRef()
  component = render(<ModuleFileDrop {...props} ref={ref} />)
  ref.current.setState({folder: {files: []}})
  expect(ref.current.state.interaction).toBeTruthy()
  expect(ref.current.state.folder).toBeTruthy()
  expect(component.queryByText('Drop files here to add to module')).toBeInTheDocument()
  expect(component.queryByText('or choose files')).toBeInTheDocument()
})

it('renders invisible upload form when files are dropped', async () => {
  const ref = React.createRef()
  component = render(<ModuleFileDrop {...props} ref={ref} />)
  await ref.current.setState({
    folder: {files: []},
    isUploading: true,
    contextId: '1',
    contextType: 'Course',
  })
  expect(component.getByRole('form', {hidden: true})).toBeInTheDocument()
  expect(component.getByTestId('current-uploads')).toBeInTheDocument()
})
