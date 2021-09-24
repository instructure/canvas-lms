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

export function installIntlPolyfills() {
  if (typeof window.Intl === 'undefined') window.Intl = {}
}

class LocaleLoadError extends Error {
  constructor(result, ...rest) {
    super(...rest)
    Error.captureStackTrace && Error.captureStackTrace(this, LocaleLoadError)
    this.name = 'LocaleLoadError'
    this.result = result
  }
}

function chromeVersion() {
  const m = navigator.userAgent.match(new RegExp('Chrom(e|ium)/([0-9]+).'))
  return m ? parseInt(m[2], 10) : 0
}

//
// Intl polyfills for locale-specific output of Dates, Times, Numbers, and
// Relative Times.
//
const nativeSubsystem = {
  DateTimeFormat: Intl.DateTimeFormat,
  NumberFormat: Intl.NumberFormat,
  RelativeTimeFormat: Intl.RelativeTimeFormat
}

const polyfilledSubsystem = {}

const polyfillImports = {
  DateTimeFormat: async () => {
    await import('@formatjs/intl-datetimeformat/polyfill')
    return import('@formatjs/intl-datetimeformat/add-all-tz')
  },
  NumberFormat: () => import('@formatjs/intl-numberformat/polyfill'),
  RelativeTimeFormat: () => import('@formatjs/intl-relativetimeformat/polyfill')
}

const localeImports = {
  DateTimeFormat: l => import(`@formatjs/intl-datetimeformat/locale-data/${l}`),
  NumberFormat: l => import(`@formatjs/intl-numberformat/locale-data/${l}`),
  RelativeTimeFormat: l => import(`@formatjs/intl-relativetimeformat/locale-data/${l}`)
}

function reset(locale, subsystem) {
  Intl[subsystem] = nativeSubsystem[subsystem] // Check browser-native Intl sources first
  const localeNotNative = Intl[subsystem].supportedLocalesOf([locale]).length === 0
  return {subsystem, locale, source: localeNotNative ? 'polyfill' : 'native'}
}

// Mark a return result as a fallback locale
const fallback = r => ({...r, source: 'fallback'})

// This utility is called when changing locales midstride (Canvas normally never
// changes ENV.LOCALE except at a page load). It will if necessary dynamically load
// language and locale support for locales not supported natively in the browser.
// Called with the desired locale string and a string representing which Intl subsystem
// is to be operated on ('DateTimeFormat', 'NumberFormat', or 'RelativeTimeFormat')
//
// Returns a Promise which will resolve to an object with properties:
//      subsystem - the Intl subsystem being (possibly) polyfilled
//      locale    - the locale that was loaded
//      source    - one of 'native' or 'polyfill', indicating whether the requested locale
//                  locale is native to the browser or was loaded via a polyfill
//
// If the polyfill fails to load, the language falls back to whatever the browser's native
// language is (navigator.language), and the Promise rejects, returning a custom error
// LocaleLoadError with the `message` explaining the failure and a `result` property which
// is an object as described above, which will indicate the fallback state of the locale
// after the failure causing the error to be thrown.

async function doPolyfill(locale, subsys) {
  // Reset back to the native browser Intl subsystem and see if the requested locale
  // is one of its supported ones. If not, we need to polyfill it. First import the
  // polyfilled subsystem itself. We can only do this once as that import is not
  // idempotent, which is why we save the polyfills and only do the import if there
  // is no saved one.
  const result = reset(locale, subsys)
  if (result.source === 'polyfill') {
    // Does the requested polyfill locale exist at all? If not, do not proceed,
    // it breaks some browser behavior around .toLocaleDateString()  [???].
    try {
      await localeImports[subsys](locale)
    } catch (e) {
      throw new LocaleLoadError(
        {
          locale: navigator.language,
          subsystem: subsys,
          source: 'fallback'
        },
        e.message
      )
    }

    delete Intl[subsys]
    if (typeof polyfilledSubsystem[subsys] === 'undefined') {
      try {
        await polyfillImports[subsys]()
        polyfilledSubsystem[subsys] = Intl[subsys]
      } catch (e) {
        // restore native one and throw an error
        throw new LocaleLoadError(fallback(reset(navigator.language, subsys)), e.message)
      }
    } else {
      // Have already loaded the polyfill, just need to stuff it back in
      Intl[subsys] = polyfilledSubsystem[subsys]
    }

    // Now load the specific locale... if it fails (it shouldn't because we
    // already checked this above!!), then fall back to the navigator language.
    // Note that loading a locale onto the polyfill *is* idempotent, so it
    // won't matter if we do this multiple times.
    try {
      await localeImports[subsys](locale)
    } catch (e) {
      throw new LocaleLoadError(fallback(reset(navigator.language, subsys)), e.message)
    }
  }
  return result
}

// Convenience functions that load the Intl polyfill for each of the three
// supported subsystems supported here (we could add more if needed)
export function loadDateTimeFormatPolyfill(locale) {
  return doPolyfill(locale, 'DateTimeFormat')
}

export function loadNumberFormatPolyfill(locale) {
  return doPolyfill(locale, 'NumberFormat')
}

export function loadRelativeTimeFormatPolyfill(locale) {
  return doPolyfill(locale, 'RelativeTimeFormat')
}

// Grand cru convenience function that (maybe) polyfills everything here.
// Returns a Promise that resolves to an array of the result objects
// (see above) for each subsystem.
//
// TEMPORARY PATCH (CNVS-53338) ... these polyfillers break certain date
// and time Intl functions in recent versions of Chrome. For now, just
// skip.
export function loadAllLocalePolyfills(locale) {
  const ver = chromeVersion()
  if (ver >= 92) {
    // eslint-disable-next-line no-console
    console.info(`Skipping language polyfills for Chrome ${ver}`)
    return null
  }
  return Promise.all([
    loadDateTimeFormatPolyfill(locale),
    loadNumberFormatPolyfill(locale),
    loadRelativeTimeFormatPolyfill(locale)
  ])
}
