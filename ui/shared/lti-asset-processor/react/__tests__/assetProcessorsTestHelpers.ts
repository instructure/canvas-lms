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
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'

function makeMockTool({
  name,
  description,
  url,
  definition_id,
  contribution = false,
  context_name,
}: {
  name: string
  description: string
  url: string
  definition_id: number
  contribution?: boolean
  context_name?: string
}): LtiLaunchDefinition {
  const def: LtiLaunchDefinition = {
    definition_type: 'ContextExternalTool',
    definition_id: definition_id.toString(),
    url,
    name,
    description,
    domain: 'http://lti-13-test-tool.inseng.test',
    placements: {},
    context_name,
  }
  if (contribution) {
    def.placements.ActivityAssetProcessorContribution = {
      message_type: 'LtiDeepLinkingRequest',
      url,
      title: name,
      selection_width: 800,
      selection_height: 400,
    }
  } else {
    def.placements.ActivityAssetProcessor = {
      message_type: 'LtiDeepLinkingRequest',
      url,
      title: name,
      selection_width: 600,
      selection_height: 500,
    }
  }
  return def
}

function makeMockTools(contribution = false): LtiLaunchDefinition[] {
  const postfix = contribution ? ` Contribution` : ''
  return [
    makeMockTool({
      name: 't1' + postfix,
      description: 'd1' + postfix,
      url: 'http://t1.instructure.com.com',
      definition_id: 11,
      contribution,
    }),
    makeMockTool({
      name: 't2' + postfix,
      description: 'd2' + postfix,
      url: 'http://t2.instructure.com.com',
      definition_id: 22,
      contribution,
    }),
    makeMockTool({
      name: 't3' + postfix,
      description: 'd3' + postfix,
      url: 'http://t3.instructure.com.com',
      definition_id: 33,
      contribution,
    }),
    makeMockTool({
      name: 't4' + postfix,
      description: 'd4' + postfix,
      url: 'http://t4.instructure.com.com',
      definition_id: 44,
      contribution,
      context_name: 'Account A',
    }),
  ]
}

// MSW handler for asset processor tools
export function createAssetProcessorMswHandler() {
  return (req: any) => {
    const url = new URL(req.request.url)
    const placements = url.searchParams.get('placements[]')
    return placements === 'ActivityAssetProcessor'
      ? mockToolsForAssignment
      : mockToolsForDiscussions
  }
}

export const mockToolsForAssignment = makeMockTools(false)
export const mockToolsForDiscussions = makeMockTools(true)

// To be used with:
// useAssetProcessorsToolsList.mockReturnValue(makeMockAssetProcessorsToolsListQuery())
export const mockAssetProcessorsToolsListQuery = {
  data: mockToolsForAssignment,
  loading: false,
  error: null,
}

export const mockDeepLinkResponse: DeepLinkResponse = {
  content_items: [
    {
      type: 'ltiAssetProcessor',
      report: {},
      text: 'Lti 1.3 Tool Text',
      title: 'Lti 1.3 Tool Title',
    },
  ],
  reloadpage: false,
  tool_id: '22',
}

export const mockContributionDeepLinkResponse: DeepLinkResponse = {
  content_items: [
    {
      type: 'ltiAssetProcessorContribution',
      report: {},
      text: 'Lti 1.3 Tool Text',
      title: 'Lti 1.3 Tool Title',
    },
  ],
  reloadpage: false,
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
  reloadpage: false,
  tool_id: '44',
}

export const mockExistingAttachedAssetProcessor: ExistingAttachedAssetProcessor = {
  id: 1,
  tool_id: 2,
  tool_name: 'tool name',
  tool_placement_label: 'tool label',
  title: 'ap title',
  text: 'ap text',
  icon_or_tool_icon_url: 'http://instructure.com/icon.png',
  iframe: {
    width: 600,
    height: 500,
  },
}
