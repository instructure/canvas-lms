/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

/**
 * This will log a single deprecation notice when NODE_ENV isn't `production`.
 *
 * @param {string} message The deprecation message to log to the console. Say what should be used instead here.
 * @param {string} obj the object to deprecate `method` on
 * @param {string} method The method on `obj` to deprecate
 * @return {function} The function that will warn once and then call `fn`
 * There are 3 ways you can use this:
 * @example
 * // Most basic usage, just logs supplied deprecation message
 * $.somethingOld = deprecated("use '@instructure/ui-something-better' instead", () => { ...})
 * @example
 * // Will log a more helpful deprecation method than the first example because
 * // it will tell you the host object and name of the method that is deprecated.
 * deprecated("use '@instructure/ui-something-better' instead", $, 'somethingOld', () => { ...} )
 * @example
 * // if you want to mark a method defined somewhere else (like a lib you don't control) as deprecated
 * deprecated("use '@instructure/ui-something-better' instead", $, 'somethingOld')
 */
export default function deprecated(message, obj, method, fn) {
  const isBareFn = !method
  const originalFn = isBareFn ? obj : typeof fn === 'function' ? fn : obj[method]
  if (process.env.NODE_ENV !== 'production') {
    let warned = false
    const newFn = Object.assign(function () {
      if (!warned && console) {
        const warningArgs = isBareFn
          ? [originalFn]
          : [obj && obj.name ? obj.name : obj, `.${method} (aka: `, originalFn, ')']
        console.warn(...warningArgs, 'is deprecated.', message)
      }
      warned = true
      return originalFn.apply(this, arguments)
    }, originalFn)

    if (!isBareFn) obj[method] = newFn
    return newFn
  }
  return originalFn
}
