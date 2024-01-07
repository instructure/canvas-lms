/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import fetchMock from 'fetch-mock'
import {
  youTubeID,
  isExternalLink,
  getTld,
  showFilePreview,
  showFilePreviewInOverlay,
  showFilePreviewInline,
} from '../instructure_helper'

function makeEvent(opts) {
  return {
    preventDefault: jest.fn(),
    stopPropagation: jest.fn(),
    ...opts,
  }
}

function mockFetchPreview(href) {
  fetchMock.get(href, {attachment: {}})
}

const canvasOrigin = 'http://localhost'

describe('enhanced_user_content/instructure_helpers', () => {
  describe('youTubeID', () => {
    it('finds video id in shortened form of a youtube url', () => {
      const id = youTubeID('https://youtu.be/xyzzy')
      expect(id).toEqual('xyzzy')
    })

    it('finds the video id in the long form url', () => {
      const id = youTubeID('https://www.youtube.com/watch?v=xyzzy')
      expect(id).toEqual('xyzzy')
    })

    it('returns null for a non-youtube url', () => {
      const id = youTubeID('https://example.com/xyzzy')
      expect(id).toBeNull()
    })
  })

  describe('isExternalLink', () => {
    // in jsdom, window.location is http://localhost/

    it('finds external links', () => {
      const link = document.createElement('a')
      link.href = 'https://somewhere.else/'
      expect(isExternalLink(link)).toBeTruthy()
    })

    it('recognizes local links', () => {
      const link = document.createElement('a')
      link.href = 'https://localhost/at/some/path'
      expect(isExternalLink(link)).toBeFalsy()
    })

    it('treats originless urls as local', () => {
      const link = document.createElement('a')
      link.href = '/at/some/path'
      expect(isExternalLink(link)).toBeFalsy()
    })
  })

  describe('getTld', () => {
    it('copes with ports', () => {
      expect(getTld('company.com:3000')).toEqual('company.com')
    })

    it('copes with subdomains', () => {
      expect(getTld('sub.company.com')).toEqual('company.com')
    })

    it('copes with subdomains and ports', () => {
      expect(getTld('sub.company.com:3000')).toEqual('company.com')
    })

    it('copes with localhost', () => {
      expect(getTld('localhost:3000')).toEqual('localhost')
    })

    it('copes with gibberish', () => {
      expect(getTld('this is not a hostname at all')).toEqual('this is not a hostname at all')
    })
  })

  describe('showFilePreviewInOverlay', () => {
    beforeEach(() => {
      jest.spyOn(window, 'postMessage')
    })
    afterEach(() => {
      window.postMessage.mockRestore()
    })

    it('posts a message when link is to a canvas file', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/courses/1/files/2'
      const event = makeEvent({target: link})
      showFilePreviewInOverlay(event, canvasOrigin)
      expect(window.postMessage).toHaveBeenCalledWith(
        {
          subject: 'preview_file',
          file_id: '2',
          verifier: null,
        },
        canvasOrigin
      )
    })

    it('posts a message with the canvas file verifier', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/courses/1/files/2?verifier=xyzzy'
      const event = makeEvent({target: link})
      showFilePreviewInOverlay(event, canvasOrigin)
      expect(window.postMessage).toHaveBeenCalledWith(
        {
          subject: 'preview_file',
          file_id: '2',
          verifier: 'xyzzy',
        },
        canvasOrigin
      )
    })

    it('ignores links not to canvas files', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/notafile'
      const event = makeEvent({target: link})
      showFilePreviewInOverlay(event, canvasOrigin)
      expect(window.postMessage).not.toHaveBeenCalled()
    })

    it('ignores canvas file links clicked with a modifier key down', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/courses/1/files/2'
      const event = makeEvent({target: link, ctrlKey: true})
      showFilePreviewInOverlay(event, canvasOrigin)
      expect(window.postMessage).not.toHaveBeenCalled()
    })

    it('posts a message when link is to a canvas file with a global id', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/users/1/files/17~76640'
      const event = makeEvent({target: link})
      showFilePreviewInOverlay(event, canvasOrigin)
      expect(window.postMessage).toHaveBeenCalledWith(
        {
          subject: 'preview_file',
          file_id: '17~76640',
          verifier: null,
        },
        canvasOrigin
      )
    })
  })

  describe('showFilePreviewInline', () => {
    afterEach(() => {
      fetchMock.restore()
    })

    it('fetches the file', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/courses/1/files/2'
      mockFetchPreview(link.href)
      const event = makeEvent({currentTarget: link})
      showFilePreviewInline(event)
      expect(event.preventDefault).toHaveBeenCalled()
      return fetchMock.flush(true).then(() => {
        expect(fetchMock.called()).toBeTruthy()
      })
    })

    it('lets the the browser handle the event if the link is clicked with a modifier key down', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/courses/1/files/2'
      const event = makeEvent({currentTarget: link, ctrlKey: true})
      showFilePreviewInline(event)
      expect(event.preventDefault).not.toHaveBeenCalled()
    })
  })

  describe('showFilePreview', () => {
    const opts = {canvasOrigin, disableGooglePreviews: false}
    beforeEach(() => {
      jest.spyOn(window, 'postMessage')
    })
    afterEach(() => {
      window.postMessage.mockRestore()
      fetchMock.restore()
    })

    it('does nothing if the link has no href', () => {
      const link = document.createElement('a')
      mockFetchPreview('*')
      const event = makeEvent({target: link})
      showFilePreview(event, opts)
      expect(event.stopPropagation).toHaveBeenCalled()
      expect(window.postMessage).not.toHaveBeenCalled()
      expect(fetchMock.called('*')).toEqual(false)
    })

    it('does nothing with links having no_preview class', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/files/17'
      link.className = 'no_preview'
      mockFetchPreview(link.href)
      const event = makeEvent({target: link})
      showFilePreview(event, opts)
      expect(event.stopPropagation).toHaveBeenCalled()
      expect(window.postMessage).not.toHaveBeenCalled()
      expect(fetchMock.called(link.href)).toEqual(false)
    })

    it('previews a.inline_disabled in the overlay', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/files/17'
      link.className = 'inline_disabled'
      mockFetchPreview(link.href)
      const event = makeEvent({target: link})
      showFilePreview(event, opts)
      expect(event.stopPropagation).toHaveBeenCalled()
      expect(window.postMessage).toHaveBeenCalled()
    })

    it('previews a.preview_in_overlay in the overlay', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/files/17'
      link.className = 'preview_in_overlay'
      mockFetchPreview(link.href)
      const event = makeEvent({target: link})
      showFilePreview(event, opts)
      expect(event.stopPropagation).toHaveBeenCalled()
      expect(window.postMessage).toHaveBeenCalled()
    })

    it('previews other links inline', () => {
      const link = document.createElement('a')
      link.href = 'http://localhost/files/17'
      mockFetchPreview(link.href)
      const event = makeEvent({target: link})
      showFilePreview(event, opts)
      expect(event.stopPropagation).toHaveBeenCalled()
      expect(window.postMessage).not.toHaveBeenCalled()
      expect(fetchMock.called(link.href)).toEqual(true)
    })
  })
})
