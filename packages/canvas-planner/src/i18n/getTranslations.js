/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export default function getTranslations(locale) {
  if (!locale || locale === 'en') {
    return Promise.resolve(null)
  }

  // Most, but not all, of our translation files use _ where the locale uses -
  // (e.g. locale es-ES maps to es_ES.json but en-GB-x-ukhe is the locale and filename)
  // Let's try the _ version first. If that fails, then try the vanilla locale-based name.
  const transFileName2 = `${locale.replace(/-/g, '_')}.json`
  const promise = new Promise((resolve, reject) => {
    import(
      /* webpackChunkName: "[request]" */ `@instructure/translations/lib/canvas-planner/${transFileName2}`
    )
      .then(translations => resolve(translations))
      .catch(_err => {
        const transFileName = `${locale}.json`
        import(
          /* webpackChunkName: "[request]" */ `@instructure/translations/lib/canvas-planner/${transFileName}`
        )
          .then(translations => resolve(translations))
          .catch(err => reject(err))
      })
  })
  return promise
}
