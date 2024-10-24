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

//
// This file is a temporary solution to prividing global templates to the block editor.
//

import {type BlockTemplate} from '../../types'

import blank from './blank.json'
import knowledgeCheck from './knowledgeCheck.json'
import homePage from './homePage1.json'
import blankPage from './blankPage.json'

// returning a promise will make this easier to replace with a real API call
export const getGlobalTemplates = (): Promise<BlockTemplate[]> => {
  // @ts-expect-error
  return Promise.resolve([blank, knowledgeCheck])
}

export const getGlobalPageTemplates = (): Promise<BlockTemplate[]> => {
  // @ts-expect-error
  return Promise.resolve([blankPage, homePage])
}
