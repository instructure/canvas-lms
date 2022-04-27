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

import React from 'react'
import {connect} from 'react-redux'
import moment from 'moment-timezone'

import {CoursePace, CoursePaceItemDueDates, Module, ResponsiveSizes, StoreState} from '../../types'
import {BlackoutDate} from '../../shared/types'
import {getCoursePace, getCompression, getDueDates} from '../../reducers/course_paces'
import {getResponsiveSize, getShowProjections} from '../../reducers/ui'
import {getBlackoutDates} from '../../shared/reducers/blackout_dates'
import {Module as IModule} from './module'

// interface ItemWithDueDate extends CoursePaceItem {
//   date: moment.Moment
//   type: 'assignment' | 'blackout_date'
// }
// interface ModuleWithDueDates {
//   readonly id: string
//   readonly name: string
//   readonly position: number
//   readonly items: ItemWithDueDate[]
// }

function compareDates(a, b) {
  if ('position' in a && 'position' in b) {
    return a.position - b.position
  }
  if (!a.date && !!b.date) return -1
  if (!!a.date && !b.date) return 1
  if (!a.date && !b.date) return 0
  if (a.date.isBefore(b.date)) return -1
  if (a.date.isAfter(b.date)) return 1
  return 0
}

export function mergeAssignmentsAndBlackoutDates(
  coursePace: CoursePace,
  dueDates: CoursePaceItemDueDates,
  blackoutDates: BlackoutDate[]
) {
  // throw out any blackout dates before or after the pace start and end
  // then strip down blackout dates and assign "start_date" to "date"
  // for merging with assignment due dates
  const paceStart = moment(coursePace.start_date)
  const dueDateKeys = Object.keys(dueDates)
  let veryLastDueDate = moment('3000-01-01T00:00:00Z')
  if (dueDateKeys.length) {
    veryLastDueDate = moment(dueDates[dueDateKeys[dueDateKeys.length - 1]])
  }
  const paceEnd = coursePace.end_date ? moment(coursePace.end_date) : veryLastDueDate
  const boDates: Array<any> = blackoutDates
    .filter(bd => {
      if (bd.end_date.isBefore(paceStart)) return false
      if (bd.start_date.isAfter(paceEnd)) return false
      return true
    })
    // because due dates will never fall w/in a blackout period
    // we can just deal with one end or the other when sorting into place.
    // I chose blackout's start_date
    .map(bd => ({
      ...bd,
      date: bd.start_date,
      type: 'blackout_date'
    }))

  // merge due dates into module items
  const modules = coursePace.modules
  const modulesWithDueDates = modules.reduce(
    (runningValue: Array<any>, module: Module): Array<any> => {
      const assignmentDueDates: CoursePaceItemDueDates = dueDates

      const assignmentsWithDueDate = module.items.map(item => {
        const item_due = assignmentDueDates[item.module_item_id]
        const due_at = item_due ? moment(item_due).endOf('day') : undefined
        return {...item, date: due_at, type: 'assignment'}
      })

      runningValue.push({...module, items: assignmentsWithDueDate})
      return runningValue
    },
    []
  )

  // merge the blackout dates into each module's items
  const modulesWithBlackoutDates = modulesWithDueDates.reduce(
    (runningValue: Array<any>, module: any, index: number): Array<any> => {
      const items = module.items

      if (index === modulesWithDueDates.length - 1) {
        // the last module gets the rest of the blackout dates
        module.items.splice(module.items.length, 0, ...boDates)
        module.items.sort(compareDates)
      } else if (items.length) {
        // find the blackout dates that occur before or during
        // the item due dates
        const lastDueDate = items[items.length - 1].date
        let firstBoDateAfterModule = boDates.length
        for (let i = 0; i < boDates.length; ++i) {
          if (boDates[i].date.isAfter(lastDueDate)) {
            firstBoDateAfterModule = i
            break
          }
        }
        // merge those blackout dates into the module items
        // and remove them from the working list of blackout dates
        const boDatesWithinModule = boDates.slice(0, firstBoDateAfterModule)
        boDates.splice(0, firstBoDateAfterModule)
        module.items.splice(module.items.length, 0, ...boDatesWithinModule)
        module.items.sort(compareDates)
      }
      return runningValue.concat(module)
    },
    []
  )
  return modulesWithBlackoutDates
}
interface StoreProps {
  readonly coursePace: CoursePace
  readonly responsiveSize: ResponsiveSizes
  readonly showProjections: boolean
  readonly compression: number
  readonly blackoutDates: BlackoutDate[]
  readonly dueDates: CoursePaceItemDueDates
}
export const CoursePaceTable: React.FC<StoreProps> = ({
  coursePace,
  responsiveSize,
  showProjections,
  compression,
  blackoutDates,
  dueDates
}) => {
  const modulesWithBlackoutDates = mergeAssignmentsAndBlackoutDates(
    coursePace,
    dueDates,
    blackoutDates
  )
  return (
    <>
      {modulesWithBlackoutDates.map((module, index) => (
        <IModule
          key={`module-${module.id}`}
          index={index + 1}
          module={module}
          coursePace={coursePace}
          responsiveSize={responsiveSize}
          showProjections={showProjections}
          compression={compression}
        />
      ))}
    </>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    coursePace: getCoursePace(state),
    responsiveSize: getResponsiveSize(state),
    showProjections: getShowProjections(state),
    compression: getCompression(state),
    blackoutDates: getBlackoutDates(state),
    dueDates: getDueDates(state)
  }
}

export default connect(mapStateToProps)(CoursePaceTable)
