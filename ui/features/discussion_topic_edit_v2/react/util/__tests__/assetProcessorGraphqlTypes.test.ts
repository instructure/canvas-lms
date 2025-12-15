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
  existingAttachedAssetProcessorFromGraphql,
  ExistingAttachedAssetProcessorGraphql,
} from '@canvas/lti/model/AssetProcessor'

import {LtiAssetProcessor} from '../../../graphql/LtiAssetProcessor'
import PropTypes from 'prop-types'

describe('existingAttachedAssetProcessorFromGraphql', () => {
  function testMatchesPropTypesShape(graphqlData: ExistingAttachedAssetProcessorGraphql) {
    // mock console.error:
    vi.spyOn(console, 'error').mockImplementation(() => {})
    try {
      // Validate that the test data matches the expected GraphQL PropTypes shape
      PropTypes.checkPropTypes(
        LtiAssetProcessor.shape(),
        graphqlData,
        'prop',
        'existingAttachedAssetProcessorFromGraphql test',
      )
      expect(console.error).not.toHaveBeenCalled()
    } finally {
      // Restore console.error
      ;(console.error as any).mockRestore()
    }
  }

  it('transforms the data with all fields present', () => {
    const graphqlData: ExistingAttachedAssetProcessorGraphql = {
      _id: '123',
      title: 'Test Asset Processor',
      text: 'This is a test processor description',
      iconOrToolIconUrl: 'https://example.com/icon.png',
      externalTool: {
        _id: '456',
        name: 'Test Tool',
        labelFor: 'Test Label',
      },
      iframe: {
        width: 800,
        height: 600,
      },
      window: {
        width: 1024,
        height: 768,
        targetName: '_blank',
        windowFeatures: 'resizable=yes,scrollbars=yes',
      },
    }

    const result = existingAttachedAssetProcessorFromGraphql(graphqlData)
    testMatchesPropTypesShape(graphqlData)

    expect(result).toEqual({
      id: 123,
      title: 'Test Asset Processor',
      text: 'This is a test processor description',
      tool_id: 456,
      tool_name: 'Test Tool',
      tool_placement_label: 'Test Label',
      icon_or_tool_icon_url: 'https://example.com/icon.png',
      iframe: {
        width: 800,
        height: 600,
      },
      window: {
        width: 1024,
        height: 768,
        targetName: '_blank',
        windowFeatures: 'resizable=yes,scrollbars=yes',
      },
    })
  })

  it('transforms the data with null/undefined optional fields', () => {
    const graphqlData: ExistingAttachedAssetProcessorGraphql = {
      _id: '789',
      title: null,
      text: null,
      iconOrToolIconUrl: null,
      externalTool: {
        _id: '101',
        name: 'Minimal Tool',
        labelFor: null,
      },
      iframe: null,
      window: null,
    }

    testMatchesPropTypesShape(graphqlData)

    const result = existingAttachedAssetProcessorFromGraphql(graphqlData)

    expect(result).toEqual({
      id: 789,
      title: undefined,
      text: undefined,
      tool_id: 101,
      tool_name: 'Minimal Tool',
      tool_placement_label: undefined,
      icon_or_tool_icon_url: undefined,
      iframe: undefined,
      window: undefined,
    })
  })

  it('transforms iframe with null dimensions', () => {
    const graphqlData: ExistingAttachedAssetProcessorGraphql = {
      _id: '999',
      title: 'Iframe Test',
      text: 'Testing iframe conversion',
      iconOrToolIconUrl: null,
      externalTool: {
        _id: '888',
        name: 'Iframe Tool',
        labelFor: 'Iframe Label',
      },
      iframe: {
        width: null,
        height: 500,
      },
      window: null,
    }

    testMatchesPropTypesShape(graphqlData)

    const result = existingAttachedAssetProcessorFromGraphql(graphqlData)

    expect(result).toEqual({
      id: 999,
      title: 'Iframe Test',
      text: 'Testing iframe conversion',
      tool_id: 888,
      tool_name: 'Iframe Tool',
      tool_placement_label: 'Iframe Label',
      icon_or_tool_icon_url: undefined,
      iframe: {
        width: undefined,
        height: 500,
      },
      window: undefined,
    })
  })

  it('transforms window with partial null values', () => {
    const graphqlData: ExistingAttachedAssetProcessorGraphql = {
      _id: '777',
      title: 'Window Test',
      text: null,
      iconOrToolIconUrl: 'https://example.com/window-icon.png',
      externalTool: {
        _id: '555',
        name: 'Window Tool',
        labelFor: null,
      },
      iframe: null,
      window: {
        width: 1200,
        height: null,
        targetName: null,
        windowFeatures: 'toolbar=no',
      },
    }

    testMatchesPropTypesShape(graphqlData)

    const result = existingAttachedAssetProcessorFromGraphql(graphqlData)

    expect(result).toEqual({
      id: 777,
      title: 'Window Test',
      text: undefined,
      tool_id: 555,
      tool_name: 'Window Tool',
      tool_placement_label: undefined,
      icon_or_tool_icon_url: 'https://example.com/window-icon.png',
      iframe: undefined,
      window: {
        width: 1200,
        height: undefined,
        targetName: undefined,
        windowFeatures: 'toolbar=no',
      },
    })
  })
})
