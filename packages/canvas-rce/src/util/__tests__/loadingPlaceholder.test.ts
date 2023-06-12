/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import FakeEditor from '../../rce/__tests__/FakeEditor'
import {
  insertPlaceholder,
  PlaceholderInfo,
  placeholderInfoFor,
  removePlaceholder,
} from '../loadingPlaceholder'
import {Editor} from 'tinymce'
import {
  AUDIO_PLAYER_SIZE,
  VIDEO_SIZE_DEFAULT,
} from '../../rce/plugins/instructure_record/VideoOptionsTray/TrayController'
import {jsdomInnerText} from './jsdomInnerText'

// =====================================================================================================================
// placeholderInfoFor

describe('placeholderInfoFor', () => {
  // -------------------------------------------------------------------------------------------------------------------

  it('should handle images', async () => {
    mockImage(true, {width: 1234, height: 5678})
    expect(
      await placeholderInfoFor({
        name: 'square.png',
        domObject: {
          preview: squareImageDataUri,
        },
        contentType: 'image/png',
      })
    ).toEqual({
      type: 'block',
      ariaLabel: 'Loading placeholder for square.png',
      visibleLabel: 'square.png',
      backgroundImageUrl: squareImageDataUri,
      width: '1234px',
      height: '5678px',
      vAlign: 'middle',
    } as PlaceholderInfo)
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should handle blob images', async () => {
    mockImage(true, {width: 1234, height: 5678})

    const blob = new Blob(['whatever'], {type: 'image/png'})

    expect(
      await placeholderInfoFor({
        name: 'square.png',
        domObject: blob,
        contentType: 'image/png',
      })
    ).toEqual({
      type: 'block',
      ariaLabel: 'Loading placeholder for square.png',
      visibleLabel: 'square.png',
      backgroundImageUrl: 'http://example.com/whatever',
      width: '1234px',
      height: '5678px',
      vAlign: 'middle',
    } as PlaceholderInfo)
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should handle file images', async () => {
    mockImage(true, {width: 1234, height: 5678})

    const file = new File(['whatever'], 'square.png', {type: 'image/png'})

    expect(
      await placeholderInfoFor({
        name: 'square.png',
        domObject: file,
        contentType: 'image/png',
      })
    ).toEqual({
      type: 'block',
      ariaLabel: 'Loading placeholder for square.png',
      visibleLabel: 'square.png',
      backgroundImageUrl: 'http://example.com/whatever',
      width: '1234px',
      height: '5678px',
      vAlign: 'middle',
    } as PlaceholderInfo)
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should handle images inserted as links', async () => {
    expect(
      await placeholderInfoFor({
        name: 'square.png',
        domObject: {
          preview: squareImageDataUri,
        },
        contentType: 'image/png',
        displayAs: 'link',
      })
    ).toEqual({
      type: 'inline',
      ariaLabel: 'Loading placeholder for square.png',
      visibleLabel: 'square.png',
    })
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should handle video files', async () => {
    expect(
      await placeholderInfoFor({
        name: 'video.mp4',
        domObject: {},
        contentType: 'video/mp4',
      })
    ).toEqual({
      type: 'block',
      ariaLabel: 'Loading placeholder for video.mp4',
      visibleLabel: 'video.mp4',
      width: VIDEO_SIZE_DEFAULT.width,
      height: VIDEO_SIZE_DEFAULT.height,
      vAlign: 'bottom',
    })
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should handle audio files', async () => {
    expect(
      await placeholderInfoFor({
        name: 'audio.mp3',
        domObject: {},
        contentType: 'audio/mpeg',
      })
    ).toEqual({
      type: 'block',
      visibleLabel: 'audio.mp3',
      ariaLabel: 'Loading placeholder for audio.mp3',
      width: AUDIO_PLAYER_SIZE.width,
      height: AUDIO_PLAYER_SIZE.height,
      vAlign: 'bottom',
    })
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should handle other files', async () => {
    expect(
      await placeholderInfoFor({
        name: 'file.txt',
        domObject: {},
        contentType: 'text/plain',
      })
    ).toEqual({
      type: 'inline',
      visibleLabel: 'file.txt',
      ariaLabel: 'Loading placeholder for file.txt',
    })
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should prefer title over name if available', async () => {
    expect(
      await placeholderInfoFor({
        name: 'file.txt',
        domObject: {},
        contentType: 'text/plain',
        title: 'actual-file-name.txt',
      })
    ).toEqual({
      type: 'inline',
      visibleLabel: 'actual-file-name.txt',
      ariaLabel: 'Loading placeholder for actual-file-name.txt',
    })
  })
})

// =====================================================================================================================
// insertPlaceholder

describe('insertPlaceholder', () => {
  // -------------------------------------------------------------------------------------------------------------------

  it('should insert inline placeholders', async () => {
    await insertPlaceholder(
      editor,
      'test-file.txt',
      Promise.resolve({
        type: 'inline',
        visibleLabel: 'test-file.txt',
        ariaLabel: 'Loading placeholder for test-file.txt',
      })
    )

    const placeholderElem = editor.dom.doc.querySelector(
      '*[data-placeholder-for=test-file\\.txt]'
    ) as HTMLElement

    expect(jsdomInnerText(placeholderElem)).toContain('test-file.txt')
  })

  // -------------------------------------------------------------------------------------------------------------------

  it('should insert block placeholders', async () => {
    await insertPlaceholder(
      editor,
      'test-file.png',
      Promise.resolve({
        type: 'block',
        visibleLabel: 'test-file.png',
        ariaLabel: 'Loading placeholder for test-file.png',
        width: '123px',
        height: '456px',
        vAlign: 'middle',
      })
    )

    const placeholderElem = editor.dom.doc.querySelector(
      '*[data-placeholder-for=test-file\\.png]'
    ) as HTMLElement

    expect(jsdomInnerText(placeholderElem)).toContain('test-file.png')
    expect(placeholderElem.style).toMatchObject({
      width: '123px',
      height: '456px',
      verticalAlign: 'middle',
    })
  })
})

// =====================================================================================================================
// removePlaceholder

describe('removePlaceholder', () => {
  // -------------------------------------------------------------------------------------------------------------------

  it('should remove placeholders', async () => {
    const info = placeholderInfoFor({
      name: 'test.txt',
      domObject: {
        preview: squareImageDataUri,
      },
      contentType: 'plain/text',
    })

    await insertPlaceholder(editor, 'test.txt', info)

    expect(editor.dom.doc.querySelector('*[data-placeholder-for=test\\.txt]')).not.toBeNull()

    removePlaceholder(editor, 'test.txt')

    expect(editor.dom.doc.querySelector('*[data-placeholder-for=square\\.png]')).toBeNull()
  })

  it('should revoke data uris', async () => {
    const info = placeholderInfoFor({
      name: 'square.png',
      domObject: {
        preview: squareImageDataUri,
      },
      contentType: 'image/png',
    })

    await insertPlaceholder(editor, 'square.png', info)

    expect(editor.dom.doc.querySelector('*[data-placeholder-for=square\\.png]')).not.toBeNull()

    removePlaceholder(editor, 'square.png')

    expect(editor.dom.doc.querySelector('*[data-placeholder-for=square\\.png]')).toBeNull()

    expect(revokeObjectURLMock).toHaveBeenCalledWith(expect.any(String))
  })
})

// =====================================================================================================================
// Setup

let editor: Editor
let revokeObjectURLMock: ReturnType<typeof jest.fn>

function mockImage(success: boolean, props: Partial<typeof global.Image> = {}) {
  // mock enough for RCEWrapper.insertPlaceholder
  global.Image = function () {
    const img = {
      ...global.Image.prototype,
      _src: null,
      width: 10,
      height: 10,
      ...props,
      get src() {
        return this._src
      },
      // when the src is set, wait a tick then call the onload handler
      set src(newSrc) {
        this._src = newSrc
        requestAnimationFrame(() => (success ? this.onload?.() : this.onerror?.()))
      },
    }
    return img
  } as any
}

// ---------------------------------------------------------------------------------------------------------------------

beforeEach(() => {
  editor = new FakeEditor() as unknown as Editor

  revokeObjectURLMock = URL.revokeObjectURL = jest.fn()
})

// ---------------------------------------------------------------------------------------------------------------------

const squareImageDataUri =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFElEQVR42mNk+A+ERADGUYX0VQgAXAYT9xTSUocAAAAASUVORK5CYII='
