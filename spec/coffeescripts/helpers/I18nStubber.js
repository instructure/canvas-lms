/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n, {useTranslations} from '@canvas/i18n'
import enTranslations from 'translations/en.json'

const frames = []

export default {
  pushFrame() {
    frames.push({
      locale: I18n.locale,
      translations: I18n.translations,
    })
    I18n.locale = null
    I18n.translations = {en: {}}
    I18n.fallbacksMap = null
  },
  popFrame() {
    if (!frames.length) throw 'I18nStubber: pop without a stored frame'
    const {locale, translations} = frames.pop()
    I18n.locale = locale
    I18n.translations = translations
    I18n.fallbacksMap = null
  },
  clear() {
    while (frames.length > 0) this.popFrame()
  },
  useInitialTranslations() {
    this.pushFrame()
    I18n.locale = 'en'
    I18n.translations = {en: enTranslations}
  },
  stub(locale, translations, cb) {
    if (cb) {
      return this.withFrame(() => this.stub(locale, translations), cb)
    }
    if (!frames.length) throw 'I18nStubber: stub without a stored frame'

    // don't merge into a given locale, just replace everything wholesale
    if (typeof locale === 'object') {
      I18n.translations = locale
    } else {
      I18n.translations[locale] = translations
    }
  },
  setLocale(locale, cb) {
    if (!frames.length) throw 'I18nStubber: setLocale without a stored frame'
    return (I18n.locale = locale)
  },
  withFrame(...cbs) {
    this.pushFrame()
    cbs.forEach(cb => cb())
    return this.popFrame()
  },
}
