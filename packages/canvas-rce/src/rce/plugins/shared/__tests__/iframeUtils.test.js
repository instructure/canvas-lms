/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {findMediaPlayerIframe} from '../iframeUtils'

describe('findMediaPlayerIframe', () => {
  let wrapper, mediaIframe, shim
  beforeEach(() => {
    wrapper = document.createElement('span')
    mediaIframe = document.createElement('iframe')
    shim = document.createElement('span')
    shim.setAttribute('class', 'mce-shim')
    wrapper.appendChild(mediaIframe)
    wrapper.appendChild(shim)
  })
  it('returns the iframe if given the video iframe', () => {
    const result = findMediaPlayerIframe(mediaIframe)
    expect(result).toEqual(mediaIframe)
  })
  it('returns the iframe if given the tinymce wrapper span', () => {
    const result = findMediaPlayerIframe(wrapper)
    expect(result).toEqual(mediaIframe)
  })
  it('returns the iframe if given the shim', () => {
    const result = findMediaPlayerIframe(shim)
    expect(result).toEqual(mediaIframe)
  })
  it('does not error if given null', () => {
    const result = findMediaPlayerIframe(null)
    expect(result).toEqual(null)
  })
})
