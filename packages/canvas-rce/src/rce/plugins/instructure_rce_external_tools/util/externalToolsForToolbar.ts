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

import type {ExternalToolData} from '../../../types'

export function externalToolsForToolbar<T extends ExternalToolData>(tools: T[]): T[] {
  // Limit of not on_by_default but favorited tools is 2
  const favorited = tools.filter(it => it.favorite && !it.on_by_default).slice(0, 2) || []
  const onByDefault = tools.filter(it => it.on_by_default && it.favorite) || []

  const set = new Map<string | number, T>()
  // Remove possible overlaps between favorited and onByDefault, otherwise
  // we'd have duplicate buttons in the toolbar.
  for (const toolInfo of favorited.concat(onByDefault)) {
    set.set(toolInfo.id, toolInfo)
  }

  return Array.from(set.values()).sort((a, b) => {
    if (a.on_by_default && !b.on_by_default) {
      return -1
    } else if (!a.on_by_default && b.on_by_default) {
      return 1
    } else {
      // This *should* always be a string, but there might be cases where it isn't,
      // especially when this method is used outside of TypeScript files.
      return a.id.toString().localeCompare(b.id.toString(), undefined, {numeric: true})
    }
  })
}
