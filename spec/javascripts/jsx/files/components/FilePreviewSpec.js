/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {mount} from 'enzyme'
import TestUtils from 'react-addons-test-utils'
import ReactModal from 'react-modal'
import FilePreview from 'jsx/files/FilePreview'
import Folder from 'compiled/models/Folder'
import File from 'compiled/models/File'
import FilesCollection from 'compiled/collections/FilesCollection'
import FoldersCollection from 'compiled/collections/FoldersCollection'

let filesCollection = {}
let folderCollection = {}
let file1 = {}
let file2 = {}
let file3 = {}
let currentFolder = {}

QUnit.module('File Preview Rendering', {
  setup() {
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
        updated_at: new Date().toISOString()
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
        updated_at: new Date().toISOString()
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
        url: 'test/test/test.png'
      },
      {preflightUrl: ''}
    )

    filesCollection.add(file1)
    filesCollection.add(file2)
    filesCollection.add(file3)
    currentFolder = new Folder()
    currentFolder.files = filesCollection

    ReactModal.setAppElement(document.getElementById('fixtures'))
  },
  teardown() {
    let filesCollection = {}
    let folderCollection = {}
    let file1 = {}
    let file2 = {}
    let file3 = {}
    let currentFolder = {}
  }
})

test('clicking the info button should render out the info panel', () => {
  const component = mount(
    <FilePreview
      isOpen={true}
      query={{
        preview: '1'
      }}
      currentFolder={currentFolder}
    />
  )
  $('.ef-file-preview-header-info').click()
  equal(
    $('tr:contains("Name")')
      .find('td')
      .text(),
    'Test File.file1'
  )

  // click it again to hide it
  $('.ef-file-preview-header-info').click()
  equal($('tr:contains("Name")').length, 0)
  component.unmount()
})

test('opening the preview for one file should show navigation buttons for the previous and next files in the current folder', () => {
  const component = mount(
    <FilePreview
      isOpen={true}
      query={{
        preview: '2'
      }}
      currentFolder={currentFolder}
    />
  )

  const arrows = $('.ef-file-preview-container-arrow-link')

  equal(arrows.length, 2, 'there are two arrows shown')

  ok(
    arrows[0].href.match('preview=1'),
    'The left arrow link has an incorrect href (`preview` query string does not exist or points to the wrong id)'
  )
  ok(
    arrows[1].href.match('preview=3'),
    'The right arrow link has an incorrect href (`preview` query string does not exist or points to the wrong id)'
  )
  component.unmount()
})

test('download button should be rendered on the file preview', () => {
  const component = mount(
    <FilePreview
      isOpen={true}
      query={{
        preview: '3'
      }}
      currentFolder={currentFolder}
    />
  )

  const downloadBtn = $('.ef-file-preview-header-download')[0]
  ok(downloadBtn, 'download button renders')
  ok(downloadBtn.href.includes(file3.get('url')), 'the download button url is correct')
  component.unmount()
})

test('clicking the close button calls closePreview with the correct url', () => {
  let closePreviewCalled = false

  const component = mount(
    <FilePreview
      isOpen={true}
      query={{
        preview: '3',
        search_term: 'web',
        sort: 'size',
        order: 'desc'
      }}
      collection={filesCollection}
      closePreview={url => {
        closePreviewCalled = true
        ok(url.includes('sort=size'))
        ok(url.includes('order=desc'))
        ok(url.includes('search_term=web'))
      }}
    />
  )

  const closeButton = $('.ef-file-preview-header-close')[0]
  ok(closeButton)
  closeButton.click()
  ok(closePreviewCalled)
  component.unmount()
})
