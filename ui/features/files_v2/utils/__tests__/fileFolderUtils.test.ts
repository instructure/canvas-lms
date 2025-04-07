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

import {
  isFile,
  getUniqueId,
  pluralizeContextTypeString,
  getName,
  getCheckboxLabel,
} from '../fileFolderUtils'
import {FAKE_FILES, FAKE_FOLDERS} from '../../fixtures/fakeData'

describe('isFile', () => {
  it('returns true for a file', () => {
    expect(isFile(FAKE_FILES[0])).toBe(true)
  })

  it('returns false for a folder', () => {
    expect(isFile(FAKE_FOLDERS[0])).toBe(false)
  })
})

describe('getUniqueId', () => {
  it('returns the correct key for a file', () => {
    expect(getUniqueId(FAKE_FILES[0])).toBe(FAKE_FILES[0].uuid)
  })

  it('returns the correct key for a folder', () => {
    expect(getUniqueId(FAKE_FOLDERS[0])).toBe(FAKE_FOLDERS[0].id)
  })
})

describe('pluralizeContextTypeString', () => {
  it('returns the correct pluralized string for course', () => {
    expect(pluralizeContextTypeString('course')).toBe('courses')
  })

  it('returns the correct pluralized string for user', () => {
    expect(pluralizeContextTypeString('user')).toBe('users')
  })
})

describe('getName', () => {
  it('returns the correct name for a file', () => {
    expect(getName(FAKE_FILES[0])).toBe(FAKE_FILES[0].display_name)
  })

  it('returns the correct name for a folder', () => {
    expect(getName(FAKE_FOLDERS[0])).toBe(FAKE_FOLDERS[0].name)
  })

  it('returns filename if no display_name for file', () => {
    const file = {
      ...FAKE_FILES[0],
      display_name: '',
    }
    expect(getName(file)).toBe(file.filename)
  })
})

describe('getCheckboxLabel', () => {
  it('returns the correct label for a file with a known mimetype', () => {
    const file = FAKE_FILES[0]
    file.mime_class = 'pdf'
    const expectedLabel = `PDF File ${file.display_name}`
    expect(getCheckboxLabel(file)).toBe(expectedLabel)
  })

  it('returns the correct label for a file with blank mimetype', () => {
    const file = FAKE_FILES[0]
    file.mime_class = ''
    const expectedLabel = `File ${file.display_name}`
    expect(getCheckboxLabel(file)).toBe(expectedLabel)
  })

  it('returns the correct label for an unlocked folder', () => {
    const folder = FAKE_FOLDERS[0]
    folder.for_submissions = false
    const expectedLabel = `Folder ${folder.name}`
    expect(getCheckboxLabel(folder)).toBe(expectedLabel)
  })

  it('returns the correct label for a locked folder', () => {
    const folder = FAKE_FOLDERS[0]
    folder.for_submissions = true
    const expectedLabel = `Folder Locked ${folder.name}`
    expect(getCheckboxLabel(folder)).toBe(expectedLabel)
  })
})
