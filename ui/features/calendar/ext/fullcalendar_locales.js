/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import 'fullcalendar'
import 'fullcalendar/dist/lang-all'

// fullcalendar's locale bundle configures moment's locales too and overrides
// ours..
//
// Since such a workaround did not exist prior to introducing the Catalan
// language support, I'm assuming it's not affecting other languages. If that
// turns out not to be the case, though, either extend this or revisit the
// whole approach (e.g. import fullcalendar's locales earlier in the build)
import reconfigureMomentCALocale from '../../../ext/custom_moment_locales/ca.js'

reconfigureMomentCALocale()
