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

import UiConfig from '../ui_config'
import FileFilter from '../file_filter'

let uiConf

describe('UiConfig', () => {
  beforeEach(() => {
    uiConf = new UiConfig({
      maxUploads: 1,
      maxFileSize: 1,
      maxTotalSize: 3,
    })
  })

  function stubFilter(withExtension) {
    return {
      includesExtension(ext) {
        return withExtension
      },
    }
  }

  function createFileFilter(type, extensions) {
    return new FileFilter({
      extensions,
      id: type,
    })
  }

  function stubFile(name, size) {
    return {
      name,
      size,
    }
  }

  it('addFileFilter', function () {
    const first = {testing: true}
    const second = {other: true}
    uiConf.addFileFilter(first)
    uiConf.addFileFilter(second)
    expect(uiConf.fileFilters.length).toEqual(2)
  })

  it('filterFor', function () {
    const first = stubFilter(false)
    const second = stubFilter(false)
    const good = stubFilter(true)

    uiConf.addFileFilter(first)
    uiConf.addFileFilter(second)

    let result = uiConf.filterFor('doesnt matter method is stubbed')
    expect(result).toBeUndefined()

    uiConf.addFileFilter(good)
    result = uiConf.filterFor('doesnt matter method is stubbed')
    expect(result).toEqual(good)
  })

  it('acceptableFile - type', function () {
    const acceptedTypes = ['video', 'audio']
    let res

    uiConf.addFileFilter(createFileFilter('video', '*.mov;*.ogg'))
    uiConf.addFileFilter(createFileFilter('audio', '*.mp3;*.aif'))

    const file = stubFile('testing.mov', 1234)
    res = uiConf.acceptableFile(file, acceptedTypes)
    expect(res).toBeTruthy()

    file.name = 'testing.mp3'
    res = uiConf.acceptableFile(file, acceptedTypes)
    expect(res).toBeTruthy()

    file.name = 'testing.doc'
    res = uiConf.acceptableFile(file, acceptedTypes)
    expect(res).toBeFalsy()
  })

  it('acceptableFile - size', () => {
    const file = stubFile('testfile.mp3', 1024 * 1025 + 1) // 1 byte about 1MB
    uiConf.addFileFilter(createFileFilter('audio', '*.mp3;*.aif'))
    const res = uiConf.acceptableFile(file, ['audio']) // 1 byte above 1MB
    expect(res).toBeFalsy()
  })
})
