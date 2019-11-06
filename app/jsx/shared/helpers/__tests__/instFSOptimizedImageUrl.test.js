/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import instFSOptimizedImageUrl from '../instFSOptimizedImageUrl'

describe('instFSOptimizedImageUrl', () => {
  it('only adds query string params to things that look like inst-fs urls', () => {
    expect(
      instFSOptimizedImageUrl('https://instructure-uploads.s3.amazonaws.com/foo', {x: 100, y: 50})
    ).toEqual('https://instructure-uploads.s3.amazonaws.com/foo')

    expect(
      instFSOptimizedImageUrl(
        'https://inst-fs-iad-beta.inscloudgate.net/files/blah/foo?download=1&token=abcxyz',
        {x: 100, y: 50}
      )
    ).toEqual(
      'https://inst-fs-iad-beta.inscloudgate.net/files/blah/foo?download=1&token=abcxyz&geometry=100x50'
    )
  })
})
