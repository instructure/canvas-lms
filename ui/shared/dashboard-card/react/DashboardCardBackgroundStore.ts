/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {uniq, filter, groupBy, chain, keys, sample, difference, each} from 'lodash'
import createStore, {type CanvasStore} from '@canvas/backbone/createStore'
import ContextColorer from '@canvas/util/contextColorer'

const DEFAULT_COLOR_OPTIONS = [
  '#008400',
  '#91349B',
  '#E1185C',
  '#D41E00',
  '#0076B8',
  '#626E7B',
  '#4D3D4D',
  '#254284',
  '#986C16',
  '#177B63',
  '#324A4D',
  '#3C4F36',
]

const customColorsHash = (ENV.PREFERENCES && ENV.PREFERENCES.custom_colors) || {}

// @ts-expect-error
const DashboardCardBackgroundStore: CanvasStore<{
  courseColors: Record<string, string>
  usedDefaults: string[]
}> & {
  colorForCourse: (courseAssetString: string) => string
  getCourseColors: () => Record<string, string>
  getUsedDefaults: () => string[]
  setColorForCourse: (courseAssetString?: string, colorCode?: string) => void
  setDefaultColors: (allCourseAssetStrings: string[]) => void
  setDefaultColor: (courseAssetString: string) => void
  leastUsedDefaults: () => string[]
  markColorUsed: (usedColor: string) => void
  persistNewColor: (courseAssetString: string, colorForCourse: string) => void
} = createStore({
  courseColors: customColorsHash,
  usedDefaults: [],
})

// ===============
//    GET STATE
// ===============

DashboardCardBackgroundStore.colorForCourse = function (courseAssetString: string) {
  return this.getCourseColors()[courseAssetString]
}

DashboardCardBackgroundStore.getCourseColors = function () {
  return this.getState().courseColors
}

DashboardCardBackgroundStore.getUsedDefaults = function () {
  return this.getState().usedDefaults
}

// ===============
//    SET STATE
// ===============

// @ts-expect-error
DashboardCardBackgroundStore.setColorForCourse = function (
  courseAssetString: string,
  colorCode: string
) {
  const originalColors = this.getCourseColors()
  const newColors = {...originalColors, [courseAssetString]: colorCode}
  this.setState({courseColors: newColors})
}

DashboardCardBackgroundStore.setDefaultColors = function (allCourseAssetStrings) {
  const customCourseAssetStrings = keys(this.getCourseColors())
  const nonCustomStrings = difference(allCourseAssetStrings, customCourseAssetStrings)
  each(nonCustomStrings, (courseString: string) => this.setDefaultColor(courseString))
}

DashboardCardBackgroundStore.setDefaultColor = function (courseAssetString: string) {
  const colorForCourse = sample(this.leastUsedDefaults())
  this.setColorForCourse(courseAssetString, colorForCourse)
  // @ts-expect-error
  this.markColorUsed(colorForCourse)
  // @ts-expect-error
  this.persistNewColor(courseAssetString, colorForCourse)
}

// ===============
//     HELPERS
// ===============

DashboardCardBackgroundStore.leastUsedDefaults = function () {
  const usedDefaults = this.getUsedDefaults()

  const usedColorsByFrequency = groupBy(
    usedDefaults,
    (x: string) => filter(usedDefaults, (y: string) => x === y).length
  )

  const mostCommonColors = uniq(
    usedColorsByFrequency[chain(usedColorsByFrequency).keys().max().value()]
  )

  return difference(DEFAULT_COLOR_OPTIONS, mostCommonColors).length === 0
    ? mostCommonColors
    : difference(DEFAULT_COLOR_OPTIONS, mostCommonColors)
}

// ===============
//     ACTIONS
// ===============

DashboardCardBackgroundStore.markColorUsed = function (usedColor: string) {
  const newUsedColors = this.getUsedDefaults().concat(usedColor)
  this.setState({usedDefaults: newUsedColors})
}

DashboardCardBackgroundStore.persistNewColor = function (
  courseAssetString: string,
  colorForCourse: string
) {
  const tmp: Record<string, string> = {}
  tmp[courseAssetString] = colorForCourse
  ContextColorer.persistContextColors(tmp, ENV.current_user_id)
}

export default DashboardCardBackgroundStore
