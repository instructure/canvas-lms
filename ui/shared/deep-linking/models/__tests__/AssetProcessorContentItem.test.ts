/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
  AssetProcessorContentItem,
  assetProcessorContentItemToDto,
} from '../AssetProcessorContentItem'

describe('assetProcessorContentItemToDto', () => {
  it('converts an AssetProcessorContentItem to the format used by the assignment api', () => {
    const contentItem: AssetProcessorContentItem = {
      type: 'ltiAssetProcessor',
      url: 'http://example.com',
      title: 'example',
      text: 'example',
      icon: {url: 'http://example.com/icon'},
      thumbnail: {url: 'http://example.com/thumbnail'},
    }
    expect(assetProcessorContentItemToDto(contentItem, 1)).toEqual({
      context_external_tool_id: 1,
      url: 'http://example.com',
      title: 'example',
      text: 'example',
      icon: {url: 'http://example.com/icon'},
      thumbnail: {url: 'http://example.com/thumbnail'},
    })
  })

  it('converts an AssetProcessorContentItem to the format used by discussions mutations', () => {
    const contentItem: AssetProcessorContentItem = {
      type: 'ltiAssetProcessorContribution',
      url: 'http://example.com',
      title: 'example',
      text: 'example',
      icon: {url: 'http://example.com/icon'},
      thumbnail: {url: 'http://example.com/thumbnail'},
    }
    expect(assetProcessorContentItemToDto(contentItem, 1)).toEqual({
      context_external_tool_id: 1,
      url: 'http://example.com',
      title: 'example',
      text: 'example',
      icon: {url: 'http://example.com/icon'},
      thumbnail: {url: 'http://example.com/thumbnail'},
    })
  })
})
