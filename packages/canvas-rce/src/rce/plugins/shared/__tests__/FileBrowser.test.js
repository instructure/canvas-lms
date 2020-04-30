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
import {render} from '@testing-library/react'
import RceFileBrowser from '../FileBrowser'
import FileBrowser from '../../../../canvasFileBrowser/FileBrowser'

jest.mock('../../../../canvasFileBrowser/FileBrowser', () => {
  return jest.fn(() => 'Files Browser')
})

describe('RceFileBrowser', () => {
  afterEach(() => FileBrowser.mockClear())

  it('invokes onFileSelect callback with appropriate data when a file is selected', () => {
    const onFileSelect = jest.fn()
    render(<RceFileBrowser onFileSelect={onFileSelect} />)
    // This is the selectFile prop passed to the Canvas FileBrowser that we mocked above
    const selectFile = FileBrowser.mock.calls[0][0].selectFile
    selectFile({name: 'a file', api: {url: '/file/download', 'content-type': 'application/pdf'}})
    expect(onFileSelect).toHaveBeenCalledWith({
      name: 'a file',
      title: 'a file',
      href: '/file/download',
      content_type: 'application/pdf',
      target: '_blank',
      class: 'instructure_file_link instructure_scribd_file'
    })
  })
})
