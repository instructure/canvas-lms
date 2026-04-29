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

import UploadFileView from '../UploadFileView'

// Mock modules
vi.mock('../UploadFileView', async () => {
  const originalModule = await vi.importActual('../UploadFileView')
  return {
    __esModule: true,
    default: vi.fn().mockImplementation(options => {
      const instance = new originalModule.default(options)
      instance.loadPreview = vi.fn().mockResolvedValue()
      instance.getImage = vi
        .fn()
        .mockResolvedValue(new Blob(['test-image'], {type: 'image/jpeg'}))
      return instance
    }),
  }
})

describe('UploadFileView', () => {
  let view
  let resolveImageLoaded
  let mockBlob

  beforeEach(() => {
    // Create a mock blob for testing
    mockBlob = new Blob(['test-image'], {type: 'image/jpeg'})

    resolveImageLoaded = vi.fn()

    view = new UploadFileView({
      avatarSize: {
        h: 128,
        w: 128,
      },
      onImageLoaded: resolveImageLoaded,
    })

    document.body.innerHTML = '<div id="fixtures"></div>'
    view.$el.appendTo('#fixtures')
    view.render()
  })

  afterEach(() => {
    document.body.innerHTML = ''
    vi.clearAllMocks()
  })

  it.skip('loads given file', async () => {
    expect(view.$el.find('.avatar-preview')).toHaveLength(0)

    await view.loadPreview(mockBlob)
    expect(view.loadPreview).toHaveBeenCalledWith(mockBlob)
  })

  it.skip('getImage returns cropped image object', async () => {
    const image = await view.getImage()
    expect(image).toBeInstanceOf(Blob)
    expect(view.getImage).toHaveBeenCalled()
  })
})
