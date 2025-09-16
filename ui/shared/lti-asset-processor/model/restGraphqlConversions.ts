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
import {LtiAssetProcessor} from './LtiAssetReport'

// Converts from the non-graphQL REST representation of an ExistingAttachedAssetProcessor
// (also used in Edit Assignment page) to the shape of the LtiAssetProcessor returned
// in graphQL queries.

export function existingAttachedAssetProcessorToGraphql(
  processor: ExistingAttachedAssetProcessor,
): LtiAssetProcessor {
  return {
    _id: processor.id.toString(),
    title: processor.title ?? null,
    iconOrToolIconUrl: processor.icon_or_tool_icon_url ?? null,
    externalTool: {
      _id: processor.tool_id.toString(),
      name: processor.tool_name,
      labelFor: processor.tool_placement_label ?? null,
    },
  }
}
