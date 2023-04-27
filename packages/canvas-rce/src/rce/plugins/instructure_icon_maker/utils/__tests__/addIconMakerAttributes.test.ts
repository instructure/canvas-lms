// @ts-nocheck
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

import addIconMakerAttributes from '../addIconMakerAttributes'
import {ICON_MAKER_ATTRIBUTE, ICON_MAKER_DOWNLOAD_URL_ATTR} from '../../svg/constants'
import buildDownloadUrl from '../../../shared/buildDownloadUrl'

describe('addIconMakerAttributes', () => {
  const url = 'http://canvas.tests/files/1/download'
  let imageAttributes
  beforeEach(() => {
    imageAttributes = {src: url}
  })

  it('adds the "data-inst-icon-maker-icon" attribute with a value of "true"', () => {
    addIconMakerAttributes(imageAttributes)
    expect(imageAttributes[ICON_MAKER_ATTRIBUTE]).toBe(true)
  })

  it('adds the "data-download-url" attribute with the correct url for IM icons', () => {
    addIconMakerAttributes(imageAttributes)
    const expectedDownloadUrl = buildDownloadUrl(imageAttributes.src)
    expect(imageAttributes[ICON_MAKER_DOWNLOAD_URL_ATTR]).toBe(expectedDownloadUrl)
  })
})
