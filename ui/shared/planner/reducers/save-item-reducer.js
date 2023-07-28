/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {
  mergeNewItemsIntoDays,
  findItemInDays,
  deleteItemFromDays,
  deleteItemFromDaysAt,
} from '../utilities/daysUtils'
import {isInMomentRange} from '../utilities/dateUtils'

// This algorithm divides the timeline into 5 sections:
// distant past: we haven't started loading this yet.
// near past: we've started loading this (state.loading.partialPastDays)
// loaded: the days we're currently showing (state.days)
// near future: we've started loading these dates (state.loading.partialFutureDays)
// distant future: we haven't started loading this yet.
// The timeline looks like this:
//
//   ^
//   |                              ^ distant past
//  --- first partial past date   --|--
//   |                              \
//  --- last partial past date       } near past range
//   |                              /
//  --- first loaded day          --|--
//   |                              \
//   |                               } loaded range
//   |                              /
//  --- last loaded day           --|--
//   |                              \
//  --- first partial future date    } near future range
//   |                              /
//  --- last partial future date  --|--
//   |                              v  distant future
//   v
//
// * If a saved item's date falls into the loaded range, we should display it immediately.
// * If a saved item's date falls into the distant past or distant future, we can alert and not
// add it to anything because we know it would be loaded on further page loads.
// * If a saved item falls into the near past or near future, we need to alert and add it to the
// corresponding partially loaded days because in this case it's possible the item would have
// appeared on a page that has already been loaded. If so, we can't count on it being loaded on
// further paging, so we need to add it in memory, even if it won't be immediately displayed.
//
// We also add the item to the partially loaded dates even if we know the saved item's date is
// complete because we want to have consistent behavior based on the state the user can see. If
// the item falls into the loaded range then they can expect it to be displayed. If it's not in
// the loaded range, they will get an alert instead. This means the partially loaded days can have
// multiple dates, which otherwise doesn't happen, but this works fine.

function momentForDayAtIndex(state, days, dayIndex) {
  if (dayIndex < 0) dayIndex = days.length + dayIndex
  const day = days[dayIndex]
  if (day === undefined) return moment.invalid()
  return moment.tz(day[0], state.timeZone)
}

function itemInRange(firstDayMoment, lastDayMoment, item) {
  return isInMomentRange(item.date, firstDayMoment, lastDayMoment)
}

// The loaded range is a special case because the range of the days array can extend to infinity
// if all days in that direction are loaded (allFutureItemsLoaded or allPastItemsLoaded).
function itemDateIsLoaded(state, item) {
  let firstDayMoment, lastDayMoment
  const itemMoment = item.dateBucketMoment.clone().startOf('day')
  const today = moment.tz(state.timeZone).startOf('day')
  if (state.days.length === 0) {
    // If state.days is empty then there is no loaded range for a new item to fall
    // into, but we still want to add the item if all[Future/Past]ItemsLoaded, or if it falls on
    // today. In this case, pretend that today is present in the days array so today is in range.
    firstDayMoment = lastDayMoment = today
  } else {
    firstDayMoment = momentForDayAtIndex(state, state.days, 0)
    lastDayMoment = momentForDayAtIndex(state, state.days, -1)
    // today is always loaded, even if the only loaded items are in the future
    if (today.isBefore(firstDayMoment)) firstDayMoment = today
  }

  const isFirstOrAfter =
    state.loading.allPastItemsLoaded ||
    itemMoment.isSame(firstDayMoment) ||
    itemMoment.isAfter(firstDayMoment)

  const isLastOrBefore =
    state.loading.allFutureItemsLoaded ||
    itemMoment.isSame(lastDayMoment) ||
    itemMoment.isBefore(lastDayMoment)

  // TODO: If K5 users can create ToDos, handle the weekly planner case too

  return isFirstOrAfter && isLastOrBefore
}

function itemIsInNearPast(state, item) {
  const firstDayInPartialPastDays = momentForDayAtIndex(state, state.loading.partialPastDays, 0)
  const firstDayInDays = momentForDayAtIndex(state, state.days, 0)
  return itemInRange(firstDayInPartialPastDays, firstDayInDays, item)
}

function itemIsInNearFuture(state, item) {
  const lastDayInDays = momentForDayAtIndex(state, state.days, -1)
  const lastDayInPartialFutureDays = momentForDayAtIndex(state, state.loading.partialFutureDays, -1)
  return itemInRange(lastDayInDays, lastDayInPartialFutureDays, item)
}

export default function savePlannerItem(state, action) {
  if (!state) return undefined // leave it to other reducers to generate initial state
  if (action.type !== 'SAVED_PLANNER_ITEM') return state
  if (action.error) return state
  // Save actions from the todo sidebar that happen before the planner is loaded will mess up its
  // initial state, so we ignore them.
  if (!state.loading.plannerLoaded) return state

  const item = action.payload.item
  if (itemDateIsLoaded(state, item)) {
    const {dayIndex, itemIndex, item: oldItem} = findItemInDays(state.days, item.uniqueId)
    let nextDays = state.days
    if (oldItem && !oldItem.dateBucketMoment.isSame(item.dateBucketMoment)) {
      nextDays = deleteItemFromDaysAt(state.days, dayIndex, itemIndex)
    }
    return {...state, days: mergeNewItemsIntoDays(nextDays, [item])}
  } else if (itemIsInNearPast(state, item)) {
    const nextDays = deleteItemFromDays(state.days, item)
    const nextPartial = mergeNewItemsIntoDays(state.loading.partialPastDays, [item])
    return {...state, days: nextDays, loading: {...state.loading, partialPastDays: nextPartial}}
  } else if (itemIsInNearFuture(state, item)) {
    const nextDays = deleteItemFromDays(state.days, item)
    const nextPartial = mergeNewItemsIntoDays(state.loading.partialFutureDays, [item])
    return {...state, days: nextDays, loading: {...state.loading, partialFutureDays: nextPartial}}
  } else {
    // item is in distant past or distant future
    const nextDays = deleteItemFromDays(state.days, item)
    if (nextDays === state.days) return state
    return {...state, days: nextDays}
  }
}
