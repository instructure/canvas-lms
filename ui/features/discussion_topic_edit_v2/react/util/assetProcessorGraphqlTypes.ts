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
import {AttachedAssetProcessor} from '@canvas/lti-asset-processor/react/hooks/AssetProcessorsState'
import {AssetProcessorCommonFields} from '@canvas/deep-linking/models/AssetProcessorContentItem'

/**
 * Types for use with GraphQL -- using camelCase
 */

// Equivalent to AttachedAssetProcessorDto, but with camelCase
// Must match Mutations::AssignmentBase::LtiAssetProcessorCreateOrUpdate in Canvas GraphQL
export type AttachedAssetProcessorGraphqlMutation =
  | {
      existingId: number
    }
  | {
      newContentItem: AssetProcessorContentItemGraphqlMutation
    }

// Equivalent to AssetProcessorContentItemDto, but with camelCase
export type AssetProcessorContentItemGraphqlMutation = {
  contextExternalToolId: number
} & AssetProcessorCommonFields

export function attachedAssetProcessorGraphqlMutationFromStateAttachedProcessor({
  dto,
}: AttachedAssetProcessor): AttachedAssetProcessorGraphqlMutation {
  if ('existing_id' in dto) {
    return {existingId: dto.existing_id}
  } else {
    const {context_external_tool_id, ...rest} = dto.new_content_item
    return {
      newContentItem: {
        contextExternalToolId: parseInt(context_external_tool_id.toString(), 10),
        ...rest,
      },
    }
  }
}

// Should match shape in ui/features/discussion_topic_edit_v2/graphql/Assignment.js
export type ExistingAttachedAssetProcessorGraphql = {
  _id: string
  title: string | null
  text: string | null
  iconOrToolIconUrl: string | null
  externalTool: {
    _id: string
    name: string
    labelFor: string | null
  }
  iframe: {
    width: number | null
    height: number | null
  } | null
  window: {
    width: number | null
    height: number | null
    targetName: string | null
    windowFeatures: string | null
  } | null
}

export function existingAttachedAssetProcessorFromGraphql(
  processor: ExistingAttachedAssetProcessorGraphql,
): ExistingAttachedAssetProcessor {
  return {
    id: parseInt(processor._id),
    title: processor.title || undefined,
    text: processor.text || undefined,
    tool_id: parseInt(processor.externalTool._id),
    tool_name: processor.externalTool.name,
    tool_placement_label: processor.externalTool.labelFor || undefined,
    icon_or_tool_icon_url: processor.iconOrToolIconUrl || undefined,
    iframe: processor.iframe
      ? {
          width: processor.iframe.width || undefined,
          height: processor.iframe.height || undefined,
        }
      : undefined,
    window: processor.window
      ? {
          width: processor.window.width || undefined,
          height: processor.window.height || undefined,
          targetName: processor.window.targetName || undefined,
          windowFeatures: processor.window.windowFeatures || undefined,
        }
      : undefined,
  }
}
