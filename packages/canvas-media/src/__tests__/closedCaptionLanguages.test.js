/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 *
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

import {sortedClosedCaptionLanguageList} from '../closedCaptionLanguages'

describe('sortedClosedCaptionLanguageList', () => {
  it("sorts the user's language to the top", () => {
    expect(sortedClosedCaptionLanguageList('en')[0].id).toEqual('en')
    expect(sortedClosedCaptionLanguageList('zh-Hant')[0].id).toEqual('zh-Hant')
  })

  it('handles locales with underscores', () => {
    expect(sortedClosedCaptionLanguageList('en_GB')[0].id).toEqual('en-GB')
  })
})
