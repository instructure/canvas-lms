// @ts-nocheck
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

import type {Capability} from '@instructure/updown'
import {shouldPolyfill as spfGCL} from '@formatjs/intl-getcanonicallocales/should-polyfill'
import {shouldPolyfill as spfL} from '@formatjs/intl-locale/should-polyfill'
import {shouldPolyfill as spfPR} from '@formatjs/intl-pluralrules/should-polyfill'
import {shouldPolyfill as spfNF} from '@formatjs/intl-numberformat/should-polyfill'
import {shouldPolyfill as spfDTF} from '@formatjs/intl-datetimeformat/should-polyfill'
import {shouldPolyfill as spfRTF} from '@formatjs/intl-relativetimeformat/should-polyfill'
import {oncePerPage} from '@instructure/updown'
import {captureException} from '@sentry/browser'

declare const ENV: {
  readonly LOCALES: string[]
}

const FORMAT_JS_DIR = '/dist/@formatjs'

function localeDataFor(sys: string, locale: string): string {
  return `${FORMAT_JS_DIR}/intl-${sys}/locale-data/${locale}.js`
}

type PolyfillerUpValue = {
  subsys: string
  locale: string
  loaded?: string
  source?: string
  error?: string
}

type PolyfillerArgs = {
  subsysName: string
  should: (locale?: string) => string | boolean | undefined
  polyfill: () => Promise<unknown>
  localeLoader?: (locale: string) => Promise<void>
}

function polyfillerFactory({
  subsysName,
  should,
  polyfill,
  localeLoader,
}: PolyfillerArgs): Capability {
  const subsys = Intl[subsysName]
  const native = subsys
  const nativeName = 'Native' + subsysName

  async function up(givenLocales: Array<string>): Promise<PolyfillerUpValue> {
    // If this subsystem doesn't provide `supportedLocalesOf` then it is not
    // locale-specific, so we merely have to check if it is there.
    if (!(subsys?.supportedLocalesOf instanceof Function)) {
      if (should()) {
        await polyfill()
        return {subsys: subsysName, locale: 'all locales', source: 'polyfill'}
      }
      return {subsys: subsysName, locale: 'all locales', source: 'native'}
    }

    // If on the other hand it IS locale-specific, make sure we were actually
    // passed a localeLoader function
    if (!(localeLoader instanceof Function))
      throw new TypeError(`polyfillerFactory needs localeLoader for ${subsysName}`)

    // 'en' is the final fallback, don't settle for that unless it's the only
    // available locale, in which case we do nothing.
    const locales = [...givenLocales]
    if (locales.length < 1 || locales[0] === 'en')
      return {subsys: subsysName, locale: 'en', source: 'native'}
    if (locales.slice(-1)[0] === 'en') locales.pop()
    const fallback = locales[0] ?? 'en'

    try {
      /* eslint-disable no-await-in-loop */ // it's actually fine in for-loops
      for (const locale of locales) {
        const nativeSupport = Intl[subsysName].supportedLocalesOf([locale])
        if (nativeSupport.length > 0)
          return {subsys: subsysName, locale: nativeSupport[0], source: 'native'}

        const doable = should(locale)
        if (!doable || doable === 'en') continue
        await polyfill()
        if (typeof doable === 'string') await localeLoader(doable)
        Intl[nativeName] = native
        const retval: PolyfillerUpValue = {subsys: subsysName, locale, source: 'polyfill'}
        if (typeof doable === 'string') retval.loaded = doable
        return retval
      }
      /* eslint-enable no-await-in-loop */
      return {subsys: subsysName, locale: fallback, error: 'polyfill unavailable'}
    } catch (e) {
      const error = e instanceof Error ? e.message : String(e)
      return {subsys: subsysName, locale: fallback, error}
    }
  }

  function down(): void {
    if (subsysName) {
      delete Intl[nativeName]
      Intl[subsysName] = native
    }
  }

  return {
    up: oncePerPage('intl-polyfill-' + subsysName, async () => {
      const value = await up(ENV.LOCALES)
      return {value, down}
    }),
    requires: [], // TODO  railsparameters?
  }
}

const subsystems: {[subsys: string]: Capability} = {
  getcanonicallocales: polyfillerFactory({
    subsysName: 'getCanonicalLocales',
    should: spfGCL,
    polyfill: () => import('@formatjs/intl-getcanonicallocales/polyfill'),
  }),

  locale: polyfillerFactory({
    subsysName: 'Locale',
    should: spfL,
    polyfill: () => import('@formatjs/intl-locale/polyfill-force'),
  }),

  pluralrules: polyfillerFactory({
    subsysName: 'PluralRules',
    should: spfPR,
    polyfill: () => import('@formatjs/intl-pluralrules/polyfill-force'),
    localeLoader: (l: string) => import(localeDataFor('pluralrules', l)),
  }),

  datetimeformat: polyfillerFactory({
    subsysName: 'DateTimeFormat',
    should: spfDTF,
    polyfill: async () => {
      await import('@formatjs/intl-datetimeformat/polyfill-force')
      await import('@formatjs/intl-datetimeformat/add-all-tz')
    },
    localeLoader: (l: string) => import(localeDataFor('datetimeformat', l)),
  }),

  numberformat: polyfillerFactory({
    subsysName: 'NumberFormat',
    should: spfNF,
    polyfill: () => import('@formatjs/intl-numberformat/polyfill-force'),
    localeLoader: (l: string) => import(localeDataFor('numberformat', l)),
  }),

  relativetimeformat: polyfillerFactory({
    subsysName: 'RelativeTimeFormat',
    should: spfRTF,
    polyfill: () => import('@formatjs/intl-relativetimeformat/polyfill-force'),
    localeLoader: (l: string) => import(localeDataFor('relativetimeformat', l)),
  }),
}

function polyfillUp(...polyfills: unknown[]) {
  polyfills.forEach(polyfillResult => {
    if (typeof polyfillResult === 'undefined') return
    const r = polyfillResult as PolyfillerUpValue
    if (r.error) {
      const errorMessage = `${r.subsys} polyfill for locale "${r.locale}" failed: ${r.error}`
      // eslint-disable-next-line no-console
      console.error(errorMessage)
      captureException(
        new Error(`${r.subsys} polyfill for locale "${r.locale}" failed: ${r.error}`)
      )
    }
    if (r.source === 'polyfill')
      // eslint-disable-next-line no-console
      console.info(`${r.subsys} polyfilled "${r.loaded}" for locale "${r.locale}"`)
  })
}

// See https://formatjs.io/docs/polyfills/ for a good graphical explanation of why
// these all have to be loaded in the dependent order specified.

const level1: Capability = {
  up: polyfillUp,
  requires: [subsystems.getcanonicallocales],
}

const level2: Capability = {
  up: polyfillUp,
  requires: [level1, subsystems.locale],
}

const level3: Capability = {
  up: polyfillUp,
  requires: [level2, subsystems.pluralrules],
}

const level4: Capability = {
  up: polyfillUp,
  requires: [level3, subsystems.numberformat],
}

const IntlPolyfills: Capability = {
  up: polyfillUp,
  requires: [level4, subsystems.datetimeformat, subsystems.relativetimeformat],
}

export default IntlPolyfills
