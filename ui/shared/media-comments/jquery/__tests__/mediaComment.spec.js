//
// Copyright (C) 2023 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {getSourcesAndTracks} from '../mediaComment'
import $ from 'jquery'

describe('getSourcesAndTracks', () => {
  beforeAll(() => {
    $.getJSON = jest.fn()
  })

  it('with no attachment id', () => {
    getSourcesAndTracks(1)
    expect($.getJSON).toHaveBeenCalledWith('/media_objects/1/info', expect.anything())
  })

  it('with an attachment id', () => {
    getSourcesAndTracks(1, 4)
    expect($.getJSON).toHaveBeenCalledWith('/media_attachments/4/info', expect.anything())
  })
})
