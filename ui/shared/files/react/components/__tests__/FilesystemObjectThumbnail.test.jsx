/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, act} from '@testing-library/react'
import FilesystemObjectThumbnail from '../FilesystemObjectThumbnail'
import File from '../../../backbone/models/File'
import Folder from '../../../backbone/models/Folder'
import FilesystemObject from '../../../backbone/models/FilesystemObject'

describe('FilesystemObjectThumbnail', () => {
  describe('with file', () => {
    let file

    beforeEach(() => {
      file = new File({
        id: 65,
        thumbnail_url: 'sweet_thumbnail_url',
      })
      jest.useFakeTimers()
      jest.advanceTimersByTime(20000)
    })

    afterEach(() => {
      jest.useRealTimers()
    })

    it('displays the thumbnail image', () => {
      const {container} = render(
        <FilesystemObjectThumbnail model={file} className="customClassname" />,
      )
      expect(container.firstChild).toHaveStyle({
        backgroundImage: `url('sweet_thumbnail_url')`,
      })
    })

    it('adds class name from props to the span', () => {
      const {container} = render(
        <FilesystemObjectThumbnail model={file} className="customClassname" />,
      )
      expect(container.firstChild).toHaveClass('customClassname')
    })
  })

  describe('with folder', () => {
    let folder

    beforeEach(() => {
      folder = new Folder({id: 65})
      jest.useFakeTimers()
      jest.advanceTimersByTime(20000)
    })

    afterEach(() => {
      jest.useRealTimers()
    })

    it('adds mimeClass-folder if its a folder', () => {
      const {container} = render(
        <FilesystemObjectThumbnail model={folder} className="customClassname" />,
      )
      expect(container.firstChild).toHaveClass('mimeClass-folder')
    })

    it('adds className to i tag if set in props', () => {
      const {container} = render(
        <FilesystemObjectThumbnail model={folder} className="customClassname" />,
      )
      expect(container.firstChild).toHaveClass('customClassname')
    })
  })

  describe('with other filesystem object', () => {
    it('adds className to i tag if set in props', () => {
      const fso = new FilesystemObject({id: 65})
      fso.url = () => 'foo'
      jest.useFakeTimers()

      const {container} = render(
        <FilesystemObjectThumbnail model={fso} className="customClassname" />,
      )
      jest.advanceTimersByTime(20000)

      expect(container.firstChild).toHaveClass('customClassname')
      jest.useRealTimers()
    })
  })

  describe('checkForThumbnail', () => {
    beforeEach(() => {
      jest.useFakeTimers()
    })

    afterEach(() => {
      jest.useRealTimers()
      jest.restoreAllMocks()
    })

    it('fetches thumbnail_url and updates the display', async () => {
      const file = new File({id: 65})
      file.url = () => '/api/v1/files/65'
      file.fetch = jest.fn().mockImplementation(({success}) => {
        success(file, {thumbnail_url: 'sweet_thumbnail_url'})
      })

      const {container} = render(<FilesystemObjectThumbnail model={file} />)

      // Initially it should show an icon
      expect(container.firstChild).toHaveClass('mimeClass-file')

      // Run timers to trigger fetch
      await act(async () => {
        jest.runAllTimers()
      })

      // Verify fetch was called
      expect(file.fetch).toHaveBeenCalled()
    })
  })
})
