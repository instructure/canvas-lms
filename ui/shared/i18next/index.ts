/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import i18next from 'i18next'
import {initReactI18next, useTranslation} from 'react-i18next'
// English namespace resources loaded at init time.
// For non-English locales, the engine capability loads namespace translations
// from the compiled locale file and calls i18next.addResourceBundle() per
// namespace. See ui/engine/capabilities/I18n/index.ts.
import canvasLmsEn from '@instructure/translations/lib/canvas-lms/en.json'

let initialized = false

function initI18next(locale?: string) {
  if (initialized) {
    if (locale && locale !== i18next.language) {
      i18next.changeLanguage(locale)
    }
    return
  }

  const lng = locale || document.documentElement.getAttribute('lang') || 'en'

  i18next.use(initReactI18next).init({
    lng,
    fallbackLng: 'en',
    defaultNS: false,
    keySeparator: false,
    nsSeparator: false,
    interpolation: {
      escapeValue: false,
      // Use i18next default {{var}} syntax for newly migrated features.
      // Old @canvas/i18n uses %{var} — migrated strings should be updated.
    },
    // initImmediate: false makes init synchronous since we provide all
    // resources inline — no async backend needed.
    initImmediate: false,
    react: {
      useSuspense: false,
      // Re-render components when addResourceBundle() loads translations
      // for a new locale. Without this, components rendered before
      // translations load would show English permanently.
      bindI18nStore: 'added',
    },
    resources: {
      en: canvasLmsEn,
    },
    parseMissingKeyHandler: (key: string) => {
      if (process.env.NODE_ENV === 'development') {
        console.warn(`[i18next] missing key: "${key}"`)
      }
      return key
    },
  })

  initialized = true
}

// Auto-initialize on import. The engine capability calls initI18next(locale)
// once ENV.LOCALE is known, which syncs the language if it differs from the
// default derived from the <html lang> attribute.
initI18next()

function loadI18nextTranslations(
  locale: string,
  namespaces: Record<string, Record<string, string>>,
) {
  for (const [ns, translations] of Object.entries(namespaces)) {
    i18next.addResourceBundle(locale, ns, translations, true, true)
  }
}

export {initI18next, loadI18nextTranslations, useTranslation}
export default i18next
