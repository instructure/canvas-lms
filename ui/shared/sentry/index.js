/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {captureException} from '@sentry/browser'

// Call a function for its side-effects. If it fails, don't unwind the stack,
// instead just log the exception to Sentry and to the console.
export function isolate(f) {
  return async function() {
    try {
      // DON'T propagate the return value; if they actually need it they should
      // be doing this by hand instead
      await f.apply(this, arguments)
    }
    catch (e) {
      console.error(e)
      captureException(e)
    }
  }
}