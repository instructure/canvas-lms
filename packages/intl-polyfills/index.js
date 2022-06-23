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

// Now that Canvas is on Node 14, there is at least some support for the ICU
// functionality. In case it is not 100% complete, though, this skeleton will
// remain in case we need to add any Intl polyfills in the future. Hopefully
// we will not ever have to.

import {shouldPolyfill as spfNF} from '@formatjs/intl-numberformat/should-polyfill'
import {shouldPolyfill as spfDTF} from '@formatjs/intl-datetimeformat/should-polyfill'
import {shouldPolyfill as spfRTF} from '@formatjs/intl-relativetimeformat/should-polyfill'

export function installIntlPolyfills() {
  if (typeof window.Intl === 'undefined') window.Intl = {}
}

const shouldPolyfill = {
  NumberFormat: spfNF,
  DateTimeFormat: spfDTF,
  RelativeTimeFormat: spfRTF
}

//
// Intl polyfills for locale-specific output of Dates, Times, Numbers, and
// Relative Times.
//
const polyfillImports = {
  DateTimeFormat: async () => {
    await import('@formatjs/intl-datetimeformat/polyfill-force')
    return import(/* webpackIgnore: true */ '/dist/@formatjs/intl-datetimeformat/add-all-tz.js')
  },
  NumberFormat: () => import('@formatjs/intl-numberformat/polyfill-force'),
  RelativeTimeFormat: () => import('@formatjs/intl-relativetimeformat/polyfill-force')
}

const localeImports = {
  DateTimeFormat: l => import(/* webpackIgnore: true */ `/dist/@formatjs/intl-datetimeformat/locale-data/${l}.js` ),
  NumberFormat: l => import(/* webpackIgnore: true */ `/dist/@formatjs/intl-numberformat/locale-data/${l}.js`),
  RelativeTimeFormat: l => import(/* webpackIgnore: true */ `/dist/@formatjs/intl-relativetimeformat/locale-data/${l}.js`),
}

// Check to see if there is native support in the specified Intl subsystem for
// any of the locales given in the list (they are tried in order). If there is not
// load an appropriate locale polyfill for the list of locales from @formatjs.
//
// Return value is a Promise which resolves to an hash with the following properties:
//
//   subsys - the subsystem being operated on
//   locale - the locale that was requested
//   loaded - the locale that was actually polyfilled (is missing, an error occurred)
//   source - how that locale is available ('native' or 'polyfill')
//   error - if an error occurred, contains the error message
//
// In most cases, if none of the locales in the list have either native support
// nor can any of them be polyfilled, the subsystem will fall back to 'en' as a
// locale (this is what the browser's native Intl would also do).
//
async function doPolyfill(givenLocales, subsys) {
  // 'en' is the final fallback, don't settle for that unless it's the only
  // available locale, in which case we do nothing.
  const locales = [...givenLocales]
  if (locales.length < 1 || (locales.length === 1 && locales[0] === 'en'))
    return {subsys, locale: 'en', source: 'native'}
  if (locales.slice(-1)[0] === 'en') locales.pop()

  try {
    /* eslint-disable no-await-in-loop */ // it's actually fine in for-loops
    for (const locale of locales) {
      const native = Intl[subsys].supportedLocalesOf([locale])
      if (native.length > 0) return {subsys, locale: native[0], source: 'native'}

      const doable = shouldPolyfill[subsys](locale)
      if (!doable || doable === 'en') continue
      const origSubsys = Intl[subsys]
      await polyfillImports[subsys]()
      await localeImports[subsys](doable)
      Intl[`Native${subsys}`] = origSubsys
      return {subsys, locale, source: 'polyfill', loaded: doable}
    }
    /* eslint-enable no-await-in-loop */
    return {subsys, locale: locales[0], error: 'polyfill unavailable'}
  } catch (e) {
    return {subsys, locale: locales[0], error: e.message}
  }
}

// (Possibly) load the Intl polyfill for each of the given subsystems,
// for the best available locale in the given list.
// Returns a Promise that resolves to an array of the result objects
// (see above) for each subsystem.
// It is an error for the subsystems array to contain the name of an
// Intl subsystem that we are not prepared to polyfill.
export function loadAllLocalePolyfills(locales, subsystems) {
  subsystems.forEach(sys => {
    if (!Object.keys(shouldPolyfill).includes(sys)) {
      throw new RangeError(`Intl subsystem ${sys} is not polyfillable!`)
    }
  })

  return Promise.all(subsystems.map(sys => doPolyfill(locales, sys)))
}
