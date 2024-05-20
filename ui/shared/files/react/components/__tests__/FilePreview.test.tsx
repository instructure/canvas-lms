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
import $ from 'jquery'
import {render} from '@testing-library/react'
import FilePreview from '@canvas/files/react/components/FilePreview'
import Folder from '@canvas/files/backbone/models/Folder'
import File from '@canvas/files/backbone/models/File'
import FilesCollection from '@canvas/files/backbone/collections/FilesCollection'

let filesCollection: any
let file1: any
let file2: any
let file3: any
let currentFolder: any

describe('File Preview Rendering', () => {
  beforeEach(() => {
    // Initialize a few things to view in the preview.
    filesCollection = new FilesCollection()
    file1 = new File(
      {
        id: '1',
        cid: 'c1',
        name: 'Test File.file1',
        'content-type': 'unknown/unknown',
        size: 1000000,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      {preflightUrl: ''}
    )
    file2 = new File(
      {
        id: '2',
        cid: 'c2',
        name: 'Test File.file2',
        'content-type': 'unknown/unknown',
        size: 1000000,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      {preflightUrl: ''}
    )
    file3 = new File(
      {
        id: '3',
        cid: 'c3',
        name: 'Test File.file3',
        'content-type': 'unknown/unknown',
        size: 1000000,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        url: 'test/test/test.png',
      },
      {preflightUrl: ''}
    )
    filesCollection.add(file1)
    filesCollection.add(file2)
    filesCollection.add(file3)
    currentFolder = new Folder()
    currentFolder.files = filesCollection
  })

  test('clicking the info button should render out the info panel', () => {
    render(
      <FilePreview
        isOpen={true}
        query={{
          preview: '1',
        }}
        currentFolder={currentFolder}
      />
    )
    const infoButton = $('.ef-file-preview-header-info')
    expect(infoButton.attr('aria-expanded')).toBe('false')
    infoButton.click()
    expect($('tr:contains("Name")').find('td').text()).toBe('Test File.file1')
    expect(infoButton.attr('aria-expanded')).toBe('true')
    // click it again to hide it
    infoButton.click()
    expect($('tr:contains("Name")').length).toBe(0)
    expect(infoButton.attr('aria-expanded')).toBe('false')
  })

  test('opening the preview for one file should show navigation buttons for the previous and next files in the current folder', () => {
    render(
      <FilePreview
        isOpen={true}
        query={{
          preview: '2',
        }}
        currentFolder={currentFolder}
      />
    )
    const arrows = $('.ef-file-preview-container-arrow-link')
    expect(arrows.length).toBe(2)
    expect((arrows[0] as HTMLAnchorElement).href).toContain('preview=1')
    expect((arrows[1] as HTMLAnchorElement).href).toContain('preview=3')
  })

  test('download button should be rendered on the file preview', () => {
    render(
      <FilePreview
        isOpen={true}
        query={{
          preview: '3',
        }}
        currentFolder={currentFolder}
      />
    )
    const downloadBtn = $('.ef-file-preview-header-download')[0]
    expect(downloadBtn).toBeInTheDocument()
    expect((downloadBtn as HTMLAnchorElement).href).toContain(file3.get('url'))
  })

  test('clicking the close button calls closePreview with the correct url', () => {
    let closePreviewCalled = false
    render(
      <FilePreview
        isOpen={true}
        query={{
          preview: '3',
          search_term: 'web',
          sort: 'size',
          order: 'desc',
        }}
        collection={filesCollection}
        closePreview={(url: any) => {
          closePreviewCalled = true
          expect(url).toContain('search_term=web')
          expect(url).toContain('sort=size')
          expect(url).toContain('order=desc')
        }}
      />
    )

    const closeButton = $('.ef-file-preview-header-close')[0]
    expect(closeButton).toBeInTheDocument()
    closeButton.click()
    expect(closePreviewCalled).toBe(true)
  })
})
