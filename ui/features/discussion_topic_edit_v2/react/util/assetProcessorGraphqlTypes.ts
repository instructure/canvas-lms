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
