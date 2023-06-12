/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {addQueryParamsToUrl} from '../../../../util/url-util'

export function addParentFrameContextToUrl(
  inputUrlStr: string | null | undefined,
  containingCanvasLtiToolId: string | null | undefined
): string | null {
  if (containingCanvasLtiToolId == null || containingCanvasLtiToolId.length === 0) {
    return inputUrlStr ?? null
  }

  return addQueryParamsToUrl(inputUrlStr, {
    parent_frame_context: containingCanvasLtiToolId,
  })
}
