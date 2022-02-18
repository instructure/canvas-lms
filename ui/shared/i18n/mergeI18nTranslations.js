/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from './i18nObj'

export function setRootTranslations(locale, cb) {
  I18n.translations[locale] = cb()
}

export function setLazyTranslations(locale, scope, cbRoot, cbScope) {
  const localeTranslations = I18n.translations[locale]

  Object.defineProperty(localeTranslations, scope, {
    configurable: true,
    enumerable: true,
    get: function() {
      Object.assign(localeTranslations, cbRoot && cbRoot())
      Object.defineProperty(localeTranslations, scope, {
        configurable: false,
        enumerable: true,
        value: cbScope ? cbScope() : {},
        writable: false,
      })

      return localeTranslations[scope]
    }
  })
}
