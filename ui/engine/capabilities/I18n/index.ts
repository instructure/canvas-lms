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

import IntlPolyfills from '../IntlPolyfills'
import type {Capability} from '@instructure/updown'
import {oncePerPage} from '@instructure/updown'
import {registerTranslations} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import fallbacks from 'translations/en.json'
import {captureException} from '@sentry/browser'

declare const ENV: {
  RAILS_ENVIRONMENT: 'development' | 'test' | 'production'
  LOCALE?: string
  readonly LOCALE_TRANSLATION_FILE: string
  readonly LOCALES: string[]
  [propName: string]: unknown
}

// Backfill ENV.LOCALE from ENV.LOCALES[0] if it does not exist
const LocaleBackfill: Capability = {
  up: () => {
    if (Array.isArray(ENV.LOCALES) && typeof ENV.LOCALE === 'undefined') {
      ENV.LOCALE = ENV.LOCALES[0]
      return {
        down: () => {
          delete ENV.LOCALE
        },
      }
    }
  },
  requires: [],
}

// load the string translation file for this locale
const Translations: Capability = {
  up: oncePerPage('translations', async () => {
    const locale = ENV.LOCALE || navigator.language || 'en'

    if (ENV.RAILS_ENVIRONMENT === 'test' || locale === 'en') {
      registerTranslations(locale, fallbacks)
    } else {
      try {
        // This file should have already been put as a preload tag in <head>
        // so this request will typically resolve almost immediately.
        const {json} = await doFetchApi({
          path: ENV.LOCALE_TRANSLATION_FILE,
          includeCSRFToken: false,
        })
        if (typeof json === 'object' && json !== null) {
          registerTranslations(locale, json)
        }
      } catch {
        registerTranslations(locale, fallbacks)

        console.error(
          `CAUTION could not load translations for "${ENV.LOCALE}", falling back to US English`,
        )
        captureException(new Error(`Could not load translations for "${ENV.LOCALE}"`))
      }
    }
  }),
  requires: [LocaleBackfill],
}

const I18n: Capability = {
  up: () => {},
  requires: [IntlPolyfills, Translations],
}

export {I18n, Translations}
