/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import I18n from 'i18n!quizzes.timing'
import $ from 'jquery'
import './vendor/date' /* Date.parse */

var timing = {
  initialTime: new Date(),
  initTimes() {
    if (timing.timesReady) {
      return timing.clientServerDiff
    }
    const serverNow = Date.parse($('.now').text()) || timing.initialTime || new Date()
    const clientNow = timing.initialTime || new Date()
    timing.clientServerDiff = serverNow.getTime() - clientNow.getTime()
    timing.timesReady = true
  },
  setReferenceDate(started_at, end_at, now) {
    if (!timing.timesReady) {
      timing.initTimes()
    }
    const result = {}
    result.referenceDate = Date.parse(end_at)
    result.isDeadline = true
    $('.time_header').text(I18n.beforeLabel(I18n.t('labels.time_remaining', 'Time Remaining')))
    if (!result.referenceDate) {
      result.isDeadline = false
      $('.time_header').text(I18n.beforeLabel(I18n.t('labels.time_elapsed', 'Time Elapsed')))
      result.referenceDate = Date.parse(started_at)
    }
    result.clientServerDiff = timing.clientServerDiff
    return result
  }
}

export default timing
