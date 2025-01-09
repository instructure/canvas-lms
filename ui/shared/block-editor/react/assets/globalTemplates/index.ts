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
import homepageelementary2 from './homePageElementary2.json'
import resourcepage from './resourcePage.json'
import resourcesSage from './resourcesSage.json'
import moduleOverviewPeach from './moduleOverviewPeach.json'
import courseoverview from './courseOverview.json'
import homepage1 from './homepage1.json'
import homepage2 from './homePage2.json'
import homepage3 from './homePage3.json'
import homepage4 from './homePage4.json'
import instructorinformation from './instructorInformation.json'
import moduleoverview1 from './moduleOverview1.json'
import moduleoverview2 from './moduleOverview2.json'
import moduleoverview3 from './moduleOverview3.json'
import contentPage1 from './contentPage1.json'
import contentPage2 from './contentPage2.json'
import contentPage3 from './contentPage3.json'
import courseTour from './courseTour.json'
import moduleWrapUp1 from './moduleWrapUp1.json'
import moduleWrapUp2 from './moduleWrapUp2.json'

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
    (t: BlockTemplate) => t.map(transformTemplate),
  )
}

export const getGlobalPageTemplates = (): Promise<BlockTemplate[]> => {
  return Promise.resolve([
    blankPage,
    homepageyellow,
    homepageblue,
    homepageelementary,
    homepageelementary2,
    resourcepage,
    resourcesSage,
    moduleOverviewPeach,
    courseoverview,
    homepage1,
    homepage2,
    homepage3,
    homepage4,
    instructorinformation,
    moduleoverview1,
    moduleoverview2,
    moduleoverview3,
    contentPage1,
    contentPage2,
    contentPage3,
    courseTour,
    moduleWrapUp1,
    moduleWrapUp2,
  ]).then(
    // @ts-expect-error
    (t: BlockTemplate) => t.map(transformTemplate),
  )
}
