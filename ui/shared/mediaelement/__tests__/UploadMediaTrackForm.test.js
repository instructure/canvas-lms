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

import UploadMediaTrackForm from '../UploadMediaTrackForm'
import $ from 'jquery'
import 'jquery-migrate'

$.migrateMute = true

jest.mock('react-dom', () => ({render: jest.fn()}))
$.ajaxJSON = jest.fn().mockImplementation(() => ({}))

describe('UploadMediaTrackForm', () => {
  let form

  beforeAll(() => {
    form = new UploadMediaTrackForm('media_object_id', '/doesntmatter.mp4', 'attachment_id')
    form.$dialog = {
      disableWhileLoading: jest.fn(),
      find: jest.fn().mockReturnThis(),
      val: jest.fn(() => 'whatever'),
    }
    form.getFileContent = jest.fn(() => new $.Deferred().resolve({}))
  })

  it('uses the media attachment route if FF ON', () => {
    window.ENV.FEATURES.media_links_use_attachment_id = true
    form.onSubmit()
    expect($.ajaxJSON).toHaveBeenCalledWith(
      '/media_attachments/attachment_id/media_tracks',
      'POST',
      expect.anything(),
      expect.anything(),
      expect.anything()
    )
  })

  it('uses the media objects route if FF OFF', () => {
    window.ENV.FEATURES.media_links_use_attachment_id = false
    form.onSubmit()
    expect($.ajaxJSON).toHaveBeenCalledWith(
      '/media_objects/media_object_id/media_tracks',
      'POST',
      expect.anything(),
      expect.anything(),
      expect.anything()
    )
  })
})
