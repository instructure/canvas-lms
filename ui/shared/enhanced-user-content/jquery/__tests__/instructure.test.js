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

import $ from 'jquery'
import enhanceEverything, {enhanceUserContent} from '..'
import stubEnv from '@canvas/stub-env'
import sinon from 'sinon'

describe('enhanceUserContent()', () => {
  const subject = bodyHTML => {
    document.body.innerHTML = bodyHTML
    enhanceUserContent()
    return document.body
  }

  describe('when the link has an href and matches a file path', () => {
    const bodyHTML =
      '<a class="instructure_file_link instructure_scribd_file" href="/courses/1/files/1">file</a>'

    it('enhance the link', () => {
      expect(subject(bodyHTML).querySelector('.instructure_file_holder')).toBeInTheDocument()
    })
  })

  describe('when the link has no href attribute', () => {
    const bodyHTML = '<a class="instructure_file_link instructure_scribd_file">file</a>'
    it('does not enhance the link', () => {
      expect(subject(bodyHTML).querySelector('.instructure_file_holder')).not.toBeInTheDocument()
    })
  })

  describe('when the link has inline_disabled class', () => {
    const bodyHTML =
      '<a class="instructure_file_link instructure_scribd_file inline_disabled" href="/courses/1/files/1" target="_blank">file</a>'

    it('has the preview_in_overlay class and the target attribute', () => {
      const aTag = subject(bodyHTML).querySelector('a')
      expect(aTag.classList.value).toEqual('inline_disabled preview_in_overlay')
      expect(aTag).toHaveAttribute('target')
    })
  })

  describe('when the link has no_preview class', () => {
    const bodyHTML =
      '<a class="instructure_file_link instructure_scribd_file no_preview" href="/courses/1/files/1" target="_blank">file</a>'

    it('has href attribute as the download link and does not have the target atrribute.', () => {
      const aTag = subject(bodyHTML).querySelector('a')
      expect(aTag.classList.value).toEqual('no_preview')
      expect(aTag.getAttribute('href')).toEqual(
        'http://localhost/courses/1/files/1/download?download_frd=1'
      )
      expect(aTag).not.toHaveAttribute('target')
    })
  })

  describe('when the link has neither inline_disabled class or no_preview class', () => {
    const bodyHTML =
      '<a class="instructure_file_link instructure_scribd_file" href="/courses/1/files/1" target="_blank">file</a>'

    it('has the preview_in_overlay class and the target attribute', () => {
      const aTag = subject(bodyHTML).querySelector('a')
      expect(aTag.classList.value).toEqual('file_preview_link')
      expect(aTag).toHaveAttribute('target')
    })
  })
})

describe('enhanceUserContent:media', () => {
  const env = stubEnv({})
  let elem, sandbox

  beforeEach(() => {
    elem = document.createElement('div')
    sandbox = sinon.createSandbox({
      // properties: ['clock', 'mock', 'server', 'spy', 'stub'],
      useFakeServer: false,
      useFakeTimers: false,
    })
    document.body.appendChild(elem)
  })

  afterEach(() => {
    sandbox.restore()
    document.body.removeChild(elem)
  })

  it('youtube preview gets alt text from link data-preview-alt', () => {
    const alt = 'test alt string'
    elem.innerHTML = `
      <div class="user_content">
        <a href="#" class="instructure_video_link" data-preview-alt="${alt}">
          Link
        </a>
      </div>
    `
    sandbox.stub($, 'youTubeID').returns(47)
    enhanceUserContent(enhanceUserContent.ANY_VISIBILITY)
    expect(elem.querySelector('.media_comment_thumbnail').alt).toEqual(alt)
  })

  test('youtube preview ignores missing alt', () => {
    elem.innerHTML = `
      <div class="user_content">
        <a href="#" class="instructure_video_link">
          Link
        </a>
      </div>
    `
    sandbox.stub($, 'youTubeID').returns(47)
    enhanceUserContent(enhanceUserContent.ANY_VISIBILITY)
    expect(elem.querySelector('.media_comment_thumbnail').alt).toEqual('')
  })

  test("enhance '.instructure_inline_media_comment' in questions", () => {
    const mediaCommentThumbnailSpy = sandbox.spy($.fn, 'mediaCommentThumbnail')
    elem.innerHTML = `
      <div class="user_content"></div>
      <div class="answers">
        <a href="#" class="instructure_inline_media_comment instructure_video_link">
          link
        </a>
      </div>
    `
    enhanceUserContent(enhanceUserContent.ANY_VISIBILITY)
    expect(mediaCommentThumbnailSpy.thisValues[0].length).toEqual(1) // for .instructure_inline_media_comment
    expect(mediaCommentThumbnailSpy.thisValues[1].length).toEqual(1) // for .instructure_video_link
  })

  test('does not enhance content if ENV.SKIP_ENHANCING_USER_CONTENT is set to true', () => {
    env.SKIP_ENHANCING_USER_CONTENT = true

    const mediaCommentThumbnailSpy = sandbox.spy($.fn, 'mediaCommentThumbnail')
    elem.innerHTML = `
      <div class="user_content"></div>
      <div class="answers">
        <a href="#" class="instructure_inline_media_comment instructure_video_link">
          link
        </a>
      </div>
    `
    enhanceUserContent(enhanceUserContent.ANY_VISIBILITY)
    expect(mediaCommentThumbnailSpy.callCount).toEqual(0)
  })
})
