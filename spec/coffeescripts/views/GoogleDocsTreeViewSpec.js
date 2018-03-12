/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import GoogleDocsTreeView from 'compiled/views/GoogleDocsTreeView'

const file1 = {
  name: 'File 1',
  extension: 'tst',
  document_id: '12345',
  alternate_url: {href: '#'}
}
const fileData = {files: [file1]}
const folderData = {
  folders: [
    {
      name: 'Folder 1',
      files: [file1]
    }
  ]
}

QUnit.module('GoogleDocsTreeView')

test('renders a top level file', () => {
  const tree = new GoogleDocsTreeView({model: fileData})
  tree.render()
  equal(tree.$el.html().match(/>File 1<\/span>/).length, 1)
})

test('gives the file link a title', () => {
  const tree = new GoogleDocsTreeView({model: fileData})
  tree.render()
  equal(tree.$el.html().match(/title="View in Separate Window"/).length, 1)
})

test('renders a folder', () => {
  const tree = new GoogleDocsTreeView({model: folderData})
  tree.render()
  equal(tree.$el.html().match(/<li class="folder.*\n\s+Folder 1/).length, 1)
})

test('gives a nested file link a title', () => {
  const tree = new GoogleDocsTreeView({model: folderData})
  tree.render()
  equal(tree.$el.html().match(/title="View in Separate Window"/).length, 1)
})

test('activateFile triggers an event', () => {
  const tree = new GoogleDocsTreeView({model: fileData})
  tree.on('activate-file', file_id => equal(file_id, file1.document_id))
  tree.render()
  return tree.$('li.file').click()
})

test('activateFolder delegates through to clicking the sign', () => {
  expect(1)
  const tree = new GoogleDocsTreeView({model: folderData})
  tree.render()
  tree.$('.sign').on('click', () => ok('got clicked'))
  return tree.$('li.folder').click()
})
