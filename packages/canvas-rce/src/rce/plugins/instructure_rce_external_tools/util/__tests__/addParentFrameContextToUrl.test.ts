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

import {addParentFrameContextToUrl} from '../addParentFrameContextToUrl'

describe('addParentFrameContextToUrl.ts', () => {
  const absoluteUrl = 'http://some.url/whatever'

  it('should handle nullish and empty values', () => {
    const emptyValues = [null, undefined, '']

    emptyValues.forEach(empty => {
      expect(addParentFrameContextToUrl(absoluteUrl, empty)).toEqual(absoluteUrl)
    })

    emptyValues.forEach(empty => {
      expect(addParentFrameContextToUrl(empty, null)).toEqual(empty ?? null)
    })
  })

  it('should handle absolute URLs', () => {
    expect(addParentFrameContextToUrl('http://some.url/whatever', 'x')).toEqual(
      'http://some.url/whatever?parent_frame_context=x'
    )

    expect(addParentFrameContextToUrl('http://some.url/whatever?name=value', 'x')).toEqual(
      'http://some.url/whatever?name=value&parent_frame_context=x'
    )
  })

  it('should handle relative URLs', () => {
    expect(addParentFrameContextToUrl('/whatever', 'x')).toEqual('/whatever?parent_frame_context=x')

    expect(addParentFrameContextToUrl('/whatever?name=value', 'x')).toEqual(
      '/whatever?name=value&parent_frame_context=x'
    )
  })
})
