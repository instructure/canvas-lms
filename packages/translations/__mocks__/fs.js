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

const fs = jest.genMockFromModule('fs')

const createFakeDirent = (name, isDirectory = false) => {
  const dirent = new fs.Dirent()
  dirent.name = name
  dirent.isDirectory = () => isDirectory
  return dirent
}

const mockFiles = {
  '/canvas/packages/translations/lib': ['en.json', 'fr.json', 'es.json'].map(name =>
    createFakeDirent(name)
  ),
  '/canvas/packages': ['canvas-planner', 'canvas-rce']
}

fs.promises = {
  readdir: dir => {
    return Promise.resolve(mockFiles[dir])
  },
  mkdir: () => {
    return Promise.resolve()
  },
  writeFile: jest.fn(() => Promise.resolve())
}

module.exports = fs
