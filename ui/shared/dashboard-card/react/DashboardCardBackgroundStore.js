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

import _ from 'underscore'
import createStore from '@canvas/util/createStore'
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

const DashboardCardBackgroundStore = createStore({
  courseColors: customColorsHash,
  usedDefaults: [],
})

// ===============
//    GET STATE
// ===============

DashboardCardBackgroundStore.colorForCourse = function (courseAssetString) {
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

DashboardCardBackgroundStore.setColorForCourse = function (courseAssetString, colorCode) {
  const originalColors = this.getCourseColors()
  const newColors = {...originalColors, [courseAssetString]: colorCode}
  this.setState({courseColors: newColors})
}

DashboardCardBackgroundStore.setDefaultColors = function (allCourseAssetStrings) {
  const customCourseAssetStrings = _.keys(this.getCourseColors())
  const nonCustomStrings = _.difference(allCourseAssetStrings, customCourseAssetStrings)
  _.each(nonCustomStrings, courseString => this.setDefaultColor(courseString))
}

DashboardCardBackgroundStore.setDefaultColor = function (courseAssetString) {
  const colorForCourse = _.sample(this.leastUsedDefaults())
  this.setColorForCourse(courseAssetString, colorForCourse)
  this.markColorUsed(colorForCourse)
  this.persistNewColor(courseAssetString, colorForCourse)
}

// ===============
//     HELPERS
// ===============

DashboardCardBackgroundStore.leastUsedDefaults = function () {
  const usedDefaults = this.getUsedDefaults()

  const usedColorsByFrequency = _.groupBy(
    usedDefaults,
    x => _.filter(usedDefaults, y => x === y).length
  )

  const mostCommonColors = _.uniq(
    usedColorsByFrequency[_.chain(usedColorsByFrequency).keys().max().value()]
  )

  return _.difference(DEFAULT_COLOR_OPTIONS, mostCommonColors).length === 0
    ? mostCommonColors
    : _.difference(DEFAULT_COLOR_OPTIONS, mostCommonColors)
}

// ===============
//     ACTIONS
// ===============

DashboardCardBackgroundStore.markColorUsed = function (usedColor) {
  const newUsedColors = this.getUsedDefaults().concat(usedColor)
  this.setState({usedDefaults: newUsedColors})
}

DashboardCardBackgroundStore.persistNewColor = function (courseAssetString, colorForCourse) {
  const tmp = {}
  tmp[courseAssetString] = colorForCourse
  ContextColorer.persistContextColors(tmp, ENV.current_user_id)
}

export default DashboardCardBackgroundStore
