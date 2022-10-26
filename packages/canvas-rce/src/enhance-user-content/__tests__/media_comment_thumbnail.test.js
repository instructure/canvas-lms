/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import mediaCommentThumbnail from '../media_comment_thumbnail'

const kalturaSettings = {
  resource_domain: 'example.com',
  partner_id: '12345',
}

describe('mediaCommentThumbnail', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div id="fixtures">
      <a
        id="media_comment_23"
        class="instructure_inline_media_comment video_comment"
        href="/media_objects/23"
        data-author="Tom"
        data-created_at="Oct 22 at 7:10pm"
      >
        this is a media comment
      </a>
    </div>`
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('creates a thumbnail span with a background image URL generated from kaltura settings and media id', async () => {
    await mediaCommentThumbnail(
      document.getElementById('media_comment_23'),
      'normal',
      true,
      kalturaSettings
    )

    expect(document.querySelectorAll('.media_comment_thumbnail').length).toEqual(1)
    expect(document.querySelector('.media_comment_thumbnail').style['background-image']).toContain(
      `https://example.com/p/12345/thumbnail/entry_id/23/width/140/height/100/bgcolor/000000/type/2/vid_sec/5`
    )
  })

  it('creates screenreader text describing media comment', async function () {
    await mediaCommentThumbnail(
      document.getElementById('media_comment_23'),
      'normal',
      true,
      kalturaSettings
    )
    const screenreaderText = document
      .querySelector('.media_comment_thumbnail .screenreader-only')
      .textContent.trim()
    expect(screenreaderText).toEqual('Play media comment by Tom from Oct 22 at 7:10pm.')
  })

  it('creates generic screenreader text if no authoring info provided', async function () {
    document.getElementById('fixtures').innerHTML = `
      <a
        id="media_comment_23"
        class="instructure_inline_media_comment video_comment"
        href="/media_objects/23"
      >
        this is a media comment
      </a>
    `

    await mediaCommentThumbnail(
      document.getElementById('media_comment_23'),
      'normal',
      true,
      kalturaSettings
    )

    const screenreaderText = document
      .querySelector('.media_comment_thumbnail .screenreader-only')
      .textContent.trim()
    expect(screenreaderText).toEqual('Play media comment.')
  })
})
