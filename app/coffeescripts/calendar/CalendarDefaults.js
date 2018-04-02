/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import {isRTL} from 'jsx/shared/helpers/rtlHelper'

export default {
  allDayDefault: false,
  fixedWeekCount: false,
  timezone: window.ENV.TIMEZONE,
  // We do our own caching with our EventDataSource, so there's no need for
  // fullcalendar to also cache.
  lazyFetching: false,
  dragRevertDuration: 0,
  isRTL: isRTL(),

  // localization config
  // note: timeFormat && columnFormat change based on lang
  lang: window.ENV.FULLCALENDAR_LOCALE
}
