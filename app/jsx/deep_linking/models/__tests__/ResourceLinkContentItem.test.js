/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import ResourceLinkContentItem from '../ResourceLinkContentItem'

const url ='https://www.test.com/launch'
const endpoint = 'http://test.canvas.com/accounts/1/external_tools/retrieve'
const json = {
  url
}

const resourceLinkContentItem = (overrides, launchEndpoint) => {
  const mergedJson = {...json, ...overrides}
  return new ResourceLinkContentItem(
    mergedJson,
    launchEndpoint
  )
}

describe('constructor', () => {
  it('sets the url to the canvas launch endpoint', () => {
    expect(resourceLinkContentItem({}, endpoint).url).toEqual(
      `${endpoint}?display=borderless&url=${encodeURIComponent(url)}`
    )
  })
})