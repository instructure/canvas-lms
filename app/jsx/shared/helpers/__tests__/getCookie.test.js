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

import getCookie from '../getCookie'
import $ from 'jquery'
import 'jquery.cookie'

describe('getCookie', () => {
  it("handles decoding '=' characters in the same way $.cookie does", () => {
    const stringThatHasDoubleEqualsInIt =
      'mHDEs6mnYW2EG4KJkrPUNhjFPcV/uT5+x0YQhtSA6YrNPpzxkN4CPdxB0cX00aRhLKIW8E/uUEiRdii35tSaug=='
    document.cookie = 'foobar=' + encodeURIComponent(stringThatHasDoubleEqualsInIt)
    expect(getCookie('foobar')).toEqual(stringThatHasDoubleEqualsInIt)
    expect($.cookie('foobar')).toEqual(stringThatHasDoubleEqualsInIt)
  })

  it('handles keys that are not there the same as $.cookie', () => {
    expect($.cookie('cookieThatIsNotThere')).toBeUndefined()
    expect(getCookie('cookieThatIsNotThere')).toBeUndefined()
  })
})
