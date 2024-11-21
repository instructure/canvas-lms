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
import {transformTemplate} from '../../utils'

import blank from './blank.json'
import knowledgeCheck from './knowledgeCheck.json'
import blankPage from './blankPage.json'
import herosectiontwocolumn from './herosectiontwocolumn.json'
import herosectionfullwidth from './herosectionfullwidth.json'
import herosectionwithnavigation from './herosectionwithnavigation.json'
import cardssection from './cardssection.json'
import navigationsection from './navigationsection.json'

import homepageyellow from './homePageYellow.json'
import homepageblue from './homePageBlue.json'
import homepageelementary from './homePageElementary.json'

// returning a promise will make this easier to replace with a real API call
export const getGlobalTemplates = (): Promise<BlockTemplate[]> => {
  return Promise.resolve([
    blank as unknown as BlockTemplate,
    knowledgeCheck as unknown as BlockTemplate,
    herosectiontwocolumn as unknown as BlockTemplate,
    herosectionfullwidth as unknown as BlockTemplate,
    herosectionwithnavigation as unknown as BlockTemplate,
    cardssection as unknown as BlockTemplate,
    navigationsection as unknown as BlockTemplate,
  ]).then(
    // @ts-expect-error
    (t: BlockTemplate) => t.map(transformTemplate)
  )
}

export const getGlobalPageTemplates = (): Promise<BlockTemplate[]> => {
  return Promise.resolve([blankPage, homepageyellow, homepageblue, homepageelementary]).then(
    // @ts-expect-error
    (t: BlockTemplate) => t.map(transformTemplate)
  )
}
