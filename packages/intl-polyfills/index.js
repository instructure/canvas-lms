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

// All of these only implement the en-US locale, as do most of our tests anyway.

// Now that Canvas is on Node 14, there is at least some support for the ICU
// functionality. In case it is not 100% complete, though, this skeleton will
// remain in case we need to add any Intl polyfills in the future. Hopefully
// we will not ever have to.

export function installIntlPolyfills() {
  if (typeof window.Intl === 'undefined') window.Intl = {}
}
