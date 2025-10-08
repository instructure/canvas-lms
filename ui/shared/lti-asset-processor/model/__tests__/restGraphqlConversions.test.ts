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

import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {existingAttachedAssetProcessorToGraphql} from '../restGraphqlConversions'

describe('AssetProcessor conversion functions', () => {
  describe('existingAttachedAssetProcessorToGraphql', () => {
    it('converts basic processor data', () => {
      const input: ExistingAttachedAssetProcessor = {
        id: 123,
        tool_id: 456,
        tool_name: 'Test Tool',
      }

      const result = existingAttachedAssetProcessorToGraphql(input)

      expect(result).toEqual({
        _id: '123',
        title: null,
        iconOrToolIconUrl: null,
        externalTool: {
          _id: '456',
          name: 'Test Tool',
          labelFor: null,
        },
      })
    })

    it('converts processor with all optional fields', () => {
      const input: ExistingAttachedAssetProcessor = {
        id: 123,
        title: 'Test Title',
        tool_id: 456,
        tool_name: 'Test Tool',
        tool_placement_label: 'Test Label',
        icon_or_tool_icon_url: 'https://example.com/icon.png',
      }

      const result = existingAttachedAssetProcessorToGraphql(input)

      expect(result).toEqual({
        _id: '123',
        title: 'Test Title',
        iconOrToolIconUrl: 'https://example.com/icon.png',
        externalTool: {
          _id: '456',
          name: 'Test Tool',
          labelFor: 'Test Label',
        },
      })
    })

    it('handles undefined optional fields correctly', () => {
      const input: ExistingAttachedAssetProcessor = {
        id: 123,
        title: undefined,
        tool_id: 456,
        tool_name: 'Test Tool',
        tool_placement_label: undefined,
        icon_or_tool_icon_url: undefined,
      }

      const result = existingAttachedAssetProcessorToGraphql(input)

      expect(result).toEqual({
        _id: '123',
        title: null,
        iconOrToolIconUrl: null,
        externalTool: {
          _id: '456',
          name: 'Test Tool',
          labelFor: null,
        },
      })
    })
  })
})
