/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import * as tz from '@canvas/datetime'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import _Handlebars from 'handlebars/runtime'

const Handlebars = _Handlebars.default // because this version of handlebars has old, messed up es6 transpilation

// This file is to add the methods that depend on '../util/fcUtil'
// as registered handelbars helpers. These are not in ui/shared/handlebars-helpers/index.js
// because otherwise everypage would load fullcalendar.js (which fcUtil depends on).
// So anything that depends on these helpers in their handlbars needs to make sure
// to require this file first, so they are available as helpers.

const helpers = {
  // convert a moment to a string, using the given i18n format in the date.formats namespace
  fcMomentToDateString(date = '', i18n_format) {
    if (!date) return ''
    return tz.format(fcUtil.unwrap(date), `date.formats.${i18n_format}`)
  },

  // convert a moment to a time string, using the given i18n format in the time.formats namespace
  fcMomentToString(date = '', i18n_format) {
    if (!date) return ''
    return tz.format(fcUtil.unwrap(date), `time.formats.${i18n_format}`)
  },
}

for (const name in helpers) {
  const fn = helpers[name]
  Handlebars.registerHelper(name, fn)
}

export default Handlebars
