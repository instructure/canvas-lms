/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import YouTubeApi from 'tinymce_plugins/instructure_links/youtube_api'

const videoId = 'DgDk50dHbjM'
const link = {attr: () => {}, text: () => {}}
const vidTitle = 'this is my video title'
let ytApi

QUnit.module('YouTube API', {
  setup () {
    $.youTubeID = () => {return videoId}
    ytApi = new YouTubeApi()
  },
  teardown () {
    $.youTubeID = undefined
  }
})

test('titleYouTubeText changes the text of a link to match the title', () => {
  sinon.stub(ytApi, 'fetchYouTubeTitle').callsArgWith(1, vidTitle)
  const mock = sinon.mock(link).expects('text').withArgs(vidTitle)
  ytApi.titleYouTubeText(link)
  mock.verify()
})

test('titleYouTubeText increments the failure count on failure', () => {
  sinon.stub(ytApi, 'fetchYouTubeTitle').callsArgWith(1, null, {responseText: 'error'})
  const mock = sinon.mock(link).expects('attr').thrice()
  ytApi.titleYouTubeText(link)
  mock.verify()
})
