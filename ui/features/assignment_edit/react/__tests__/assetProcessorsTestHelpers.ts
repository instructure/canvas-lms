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

import {DeepLinkResponse} from '@canvas/deep-linking/DeepLinkResponse'
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'

function makeMockTool({
  name,
  description,
  url,
  definition_id,
}: {name: string; description: string; url: string; definition_id: number}): LtiLaunchDefinition {
  return {
    definition_type: 'ContextExternalTool',
    definition_id: definition_id.toString(),
    url,
    name,
    description,
    domain: 'http://lti-13-test-tool.inseng.test',
    placements: {
      ActivityAssetProcessor: {
        message_type: 'LtiDeepLinkingRequest',
        url,
        title: name,
        selection_width: 600,
        selection_height: 500,
      },
    },
  }
}

function makeMockTools(): LtiLaunchDefinition[] {
  return [
    makeMockTool({
      name: 't1',
      description: 'd1',
      url: 'http://t1.instructure.com.com',
      definition_id: 11,
    }),
    makeMockTool({
      name: 't2',
      description: 'd2',
      url: 'http://t2.instructure.com.com',
      definition_id: 22,
    }),
    makeMockTool({
      name: 't3',
      description: 'd3',
      url: 'http://t3.instructure.com.com',
      definition_id: 33,
    }),
    makeMockTool({
      name: 't4',
      description: 'd4',
      url: 'http://t4.instructure.com.com',
      definition_id: 44,
    }),
  ]
}

export function mockDoFetchApi(expectedPath: string, doFetchApi: jest.Mock) {
  doFetchApi.mockImplementation(async (...args: any[]) => {
    const {path} = args[0] as any
    if (path === expectedPath) {
      return {
        response: {ok: true, statusText: 'OK'},
        json: mockTools,
      }
    }
    throw new Error(`Unexpected path: ${path}`)
  })
}

export const mockTools = makeMockTools()

export const mockDeepLinkResponse: DeepLinkResponse = {
  content_items: [
    {
      type: 'ltiAssetProcessor',
      report: {},
      text: 'Lti 1.3 Tool Text',
      title: 'Lti 1.3 Tool Title',
    },
  ],
  ltiEndpoint: 'http://canvas-web.inseng.test/courses/1/external_tools/retrieve',
  reloadpage: false,
  replaceEditorContents: false,
  tool_id: '22',
}

export const mockInvalidDeepLinkResponse: any = {
  content_items: [
    {
      type: 'ltiAssetProcessor',
      report: {
        custom: {
          // Custom values must be strings
          error_code: 123,
        },
      },
      text: 'Lti 1.3 Tool Text',
      title: 'Lti 1.3 Tool Title',
    },
  ],
  ltiEndpoint: 'http://canvas-web.inseng.test/courses/1/external_tools/retrieve',
  reloadpage: false,
  replaceEditorContents: false,
  tool_id: '44',
}
