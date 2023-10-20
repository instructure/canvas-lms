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
import RceFileBrowser from '../RceFileBrowser'
import FileBrowser from '../../../../canvasFileBrowser/FileBrowser'

jest.mock('../../../../canvasFileBrowser/FileBrowser', () => {
  return jest.fn(() => 'Files Browser')
})
jest.mock('../../../../bridge')

const onAllFilesLoading = jest.fn()
const props = {
  searchString: '',
  onAllFilesLoading,
  host: 'canvas.docker',
  jwt: 'fakejwt',
  context: {type: 'course', id: '1'},
}

describe('RceFileBrowser', () => {
  afterEach(() => FileBrowser.mockClear())

  it('invokes onFileSelect callback with appropriate data when a file is selected', () => {
    const onFileSelect = jest.fn()
    render(<RceFileBrowser onFileSelect={onFileSelect} {...props} />)
    // This is the selectFile prop passed to the Canvas FileBrowser that we mocked above
    const selectFile = FileBrowser.mock.calls[0][0].selectFile
    selectFile({
      name: 'a file',
      src: '/file/download',
      api: {url: '/file/download?download_frd=1', type: 'application/pdf'},
    })
    expect(onFileSelect).toHaveBeenCalledWith({
      name: 'a file',
      title: 'a file',
      href: '/file?wrap=1',
      embedded_iframe_url: undefined,
      content_type: 'application/pdf',
      target: '_blank',
      class: 'instructure_file_link instructure_scribd_file inline_disabled',
    })
  })

  it('plumbs the media_id when a video file is selected', () => {
    const onFileSelect = jest.fn()
    render(<RceFileBrowser onFileSelect={onFileSelect} {...props} />)
    // This is the selectFile prop passed to the Canvas FileBrowser that we mocked above
    const selectFile = FileBrowser.mock.calls[0][0].selectFile
    selectFile({
      name: 'a video',
      src: '/file/download',
      api: {
        url: '/file/download?download_frd=1',
        type: 'video/mp4',
        embed: {id: 'm-deadbeef'},
      },
    })
    expect(onFileSelect).toHaveBeenCalledWith({
      name: 'a video',
      title: 'a video',
      href: '/file?wrap=1',
      embedded_iframe_url: '/media_objects_iframe/m-deadbeef?type=video',
      media_id: 'm-deadbeef',
      content_type: 'video/mp4',
      target: '_blank',
      class: 'instructure_file_link inline_disabled',
    })
  })

  describe('when the selected file has category=icon_maker_icon', () => {
    it('adds icon maker icon attributes to onFileSelect object param', () => {
      const onFileSelect = jest.fn()
      render(<RceFileBrowser onFileSelect={onFileSelect} {...props} />)
      // This is the selectFile prop passed to the Canvas FileBrowser that we mocked above
      const selectFile = FileBrowser.mock.calls[0][0].selectFile
      const fullUrl = 'http://dev.env/files/123/download'
      selectFile({
        name: 'a file',
        src: '/files/123/download',
        api: {
          url: fullUrl,
          name: 'awesome-icon',
          category: 'icon_maker_icons',
          type: 'image/jpg',
        },
      })
      expect(onFileSelect).toHaveBeenCalledWith(
        expect.objectContaining({
          'data-download-url': `${fullUrl}?icon_maker_icon=1`,
          'data-inst-icon-maker-icon': true,
          src: fullUrl,
        })
      )
    })
  })
})
