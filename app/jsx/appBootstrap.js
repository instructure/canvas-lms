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

import { canvas } from 'instructure-ui/lib/themes'
import moment from 'moment'
import tz from 'timezone_core'
import './fakeRequireJSFallback'

// we already put a <script> tag for the locale corresponding ENV.MOMENT_LOCALE
// on the page from rails, so this should not cause a new network request.
moment().locale(ENV.MOMENT_LOCALE)

// These timezones and locales should already be put on the page as <script>
// tags from rails. this block should not create any network requests.
if (typeof ENV !== 'undefined') {
  if (ENV.TIMEZONE) tz.changeZone(ENV.TIMEZONE)
  if (ENV.CONTEXT_TIMEZONE) tz.preload(ENV.CONTEXT_TIMEZONE)
  if (ENV.BIGEASY_LOCALE) tz.changeLocale(ENV.BIGEASY_LOCALE, ENV.MOMENT_LOCALE)
}

// setup the inst-ui default theme
if (ENV.use_high_contrast) {
  canvas.use({ accessible: true })
} else {
  const brandvars = window.CANVAS_ACTIVE_BRAND_VARIABLES || {}
  canvas.use({ overrides: brandvars })
}
