/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {type BlockTemplate} from '../types'

export const mergeTemplates = (
  apiTemplates: BlockTemplate[] | undefined,
  globalTemplates: BlockTemplate[] | undefined,
): BlockTemplate[] => {
  const templates = apiTemplates ? apiTemplates.slice() : []
  if (!globalTemplates) {
    globalTemplates = []
  }
  globalTemplates.forEach(gt => {
    const index = templates.findIndex((t: BlockTemplate) => t.id === gt.id)
    if (index >= 0) {
      templates[index] = gt
    } else {
      templates.push(gt)
    }
  })

  return templates.sort((a, b) => {
    if (a.name === 'Blank') {
      return b.name === 'Blank' ? 0 : -1
    } else if (b.name === 'Blank') {
      return a.name === 'Blank' ? 0 : 1
    }
    return a.name.localeCompare(b.name)
  })
}
