/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment-timezone'

import type {CoursePaceItem, CoursePaceItemDueDates} from '../../types'
import type {BlackoutDate} from '../../shared/types'
import * as DateHelpers from './date_helpers'

/*
  WARNING: Read this before modifying this file!

  The logic for calculating due dates is currently duplicated on both the front and backend.
  (Gross, I know). If the due date calculation logic is updated, you should also modify it in
  course_pace_due_dates_calculator.rb, so the backend will also reflect those changes.

  Ideally this should be *REFACTOR*ed at some point so the logic isn't duplicated. It's a bit
  challenging for the following reasons:

  - We want the user to get real time feedback on the frontend when they modify their pace.
    Doing an API call for every change introduces enough latency to negatively impact the user experience.
  - The frontend just POSTs the duration of each module item, and not their actual due date. We can't
    just have the frontend send the due dates, because due dates are going to be based off of an enrollment's
    start date. A published "master pace" is really just a template, and if they've  never specifically published
    for an enrollment then the frontend would never have the chance to calculate and send that student's due dates.
  - Even if we got around that issue, if a new enrollment is created through a live event we are going to
    automatically publish their pace. Which means the teacher may have never opened the tool before we create a pace
    for that student.

  For now, the logic is simple enough that the duplication isn't a big deal. But if it gets much
  more complex, we may want to schedule the necessary time to consolidate it somehow. The solutions I can think of are:

  1 - Write the date calculation logic in JavaScript and execute it on the backend using something like therubyracer
  2 - Write the date calculation logic in Ruby and compile it to JavaScript using Opal
  3 - Execute an API call on every change and just deal with the latency

  I ran into various technical difficulties trying to get #1 and #2 working, but they might be feasible if somebody
  can spend 3 or 4 days on them.
*/

export const getDueDates = (
  coursePaceItems: CoursePaceItem[],
  excludeWeekends: boolean,
  blackoutDates: BlackoutDate[],
  startDate?: string
): CoursePaceItemDueDates => {
  const dueDates: {
    [key: string]: string
  } = {}
  if (!startDate) return dueDates

  let currentStart = DateHelpers.formatDate(moment(startDate))
  for (const item of coursePaceItems) {
    currentStart = DateHelpers.addDays(currentStart, item.duration, excludeWeekends, blackoutDates)
    dueDates[item.module_item_id] = currentStart
  }

  return dueDates
}
