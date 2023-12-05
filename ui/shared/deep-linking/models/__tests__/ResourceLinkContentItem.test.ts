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

import {
  type ResourceLinkContentItem,
  resourceLinkContentItem,
  resourceLinkContentItemToHtmlString,
} from '../ResourceLinkContentItem'

const endpoint = 'http://test.canvas.com/accounts/1/external_tools/retrieve'
const title = 'Tool Title'
const lookup_uuid = '0b8fbc86-fdd7-4950-852d-ffa789b37ff2'
const url = 'http://example.com'
const json = {
  title,
  url,
  lookup_uuid,
}

const overrideResourceLinkContentItem = (overrides: Partial<ResourceLinkContentItem>) =>
  resourceLinkContentItem({
    ...json,
    ...overrides,
  })

describe('when the iframe property is specified', () => {
  const iframe = {
    src: 'http://www.instructure.com',
    width: 500,
    height: 200,
  }

  it('returns markup for an iframe', () => {
    expect(
      resourceLinkContentItemToHtmlString(overrideResourceLinkContentItem({iframe}), endpoint)
    ).toEqual(
      '<iframe src="http://test.canvas.com/accounts/1/external_tools/retrieve?display=borderless&amp;resource_link_lookup_uuid=0b8fbc86-fdd7-4950-852d-ffa789b37ff2" title="Tool Title" allowfullscreen="true" allow="" style="width: 500px; height: 200px;"></iframe>'
    )
  })
})
