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

import type {Capability} from '@instructure/updown';
import {shouldPolyfill as spfNF} from '@formatjs/intl-numberformat/should-polyfill';
import {shouldPolyfill as spfDTF} from '@formatjs/intl-datetimeformat/should-polyfill';
import {shouldPolyfill as spfRTF} from '@formatjs/intl-relativetimeformat/should-polyfill';
import {oncePerPage} from '@instructure/updown';

declare const ENV: {
  readonly LOCALES: string[];
};

const FORMAT_JS_DIR = '/dist/@formatjs';

function localeDataFor(sys: string, locale: string): string {
  return `${FORMAT_JS_DIR}/intl-${sys}/locale-data/${locale}.js`;
}

type PolyfillerUpValue = {
  subsys: string,
  locale: string,
  loaded?: string,
  source?: string,
  error?: string
};

type PolyfillerArgs = {
  subsys: Function,
  should: (locale: string) => string | undefined,
  polyfill: () => Promise<void>,
  localeLoader: (locale: string) => Promise<void>
};

function polyfillerFactory({subsys, should, polyfill, localeLoader}: PolyfillerArgs): Capability {

  const subsysName = subsys.name;
  const native = subsys;
  const nativeName = 'Native' + subsysName;

  async function up(givenLocales: Array<string>): Promise<PolyfillerUpValue> {
    // 'en' is the final fallback, don't settle for that unless it's the only
    // available locale, in which case we do nothing.
    const locales = [...givenLocales];
    if (locales.length < 1 || locales[0] === 'en')
      return {subsys: subsysName, locale: 'en', source: 'native'};
    if (locales.slice(-1)[0] === 'en') locales.pop();
    const fallback = locales[0] ?? 'en';

    try {
      /* eslint-disable no-await-in-loop */ // it's actually fine in for-loops
      for (const locale of locales) {
        const nativeSupport = Intl[subsysName].supportedLocalesOf([locale]);
        if (nativeSupport.length > 0) return {subsys: subsysName, locale: native[0], source: 'native'};

        const doable = should(locale);
        if (!doable || doable === 'en') continue;
        await polyfill();
        await localeLoader(doable);
        Intl[nativeName] = native;
        return {subsys: subsysName, locale, source: 'polyfill', loaded: doable};
      }
      /* eslint-enable no-await-in-loop */
      return {subsys: subsysName, locale: fallback, error: 'polyfill unavailable'};
    } catch (e) {
      const error = e instanceof Error ? e.message : String(e);
      return {subsys: subsysName, locale: fallback, error};
    }
  }

  function down(): void {
    delete Intl[nativeName];
    Intl[subsysName] = native;
  }

  return {
    up: oncePerPage('intl-polyfill-' + subsysName, async () => {
      const value = await up(ENV.LOCALES);
      return {value, down};
    }),
    requires: []  // TODO  railsparameters?
  };
}

const intlSubsystemsInUse: Capability[] = [
  polyfillerFactory({
    subsys: Intl.DateTimeFormat,
    should: spfDTF,
    polyfill: async () => {
      await import('@formatjs/intl-datetimeformat/polyfill-force');
      await import(/* webpackIgnore: true */ `${FORMAT_JS_DIR}/intl-datetimeformat/add-all-tz.js`);
    },
    localeLoader: (l: string) => import(/* webpackIgnore: true */ localeDataFor('datetimeformat', l))
  }),

  polyfillerFactory({
    subsys: Intl.NumberFormat,
    should: spfNF,
    polyfill: async () => {
      import('@formatjs/intl-numberformat/polyfill-force');
    },
    localeLoader: (l: string) => import(/* webpackIgnore: true */ localeDataFor('numberformat', l))
  }),

  polyfillerFactory({
    subsys: Intl.RelativeTimeFormat,
    should: spfRTF,
    polyfill: async () => {
      import('@formatjs/intl-relativetimeformat/polyfill-force');
    },
    localeLoader: (l: string) => import(/* webpackIgnore: true */ localeDataFor('relativetimeformat', l))

  })
];

const IntlPolyfills: Capability = {
  up: (...polyfills) => {
    polyfills.forEach(polyfillResult => {
      const r = polyfillResult as PolyfillerUpValue;
      if (r.error)
        // eslint-disable-next-line no-console
        console.error(`${r.subsys} polyfill for locale "${r.locale}" failed: ${r.error}`);
      if (r.source === 'polyfill')
        // eslint-disable-next-line no-console
        console.info(`${r.subsys} polyfilled "${r.loaded}" for locale "${r.locale}"`);
    });
  },
  requires: intlSubsystemsInUse
};

export default IntlPolyfills;
