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

declare module '@canvas/i18n'
declare module '@canvas/do-fetch-api-effect'

// a little disappointed this has to be done by hand
declare namespace Intl {
  function getCanonicalLocales(locales: string | string[]): string[]
  function Locale(locale: string): void
}
declare module '*.json' {
  const value: {[key: string]: string}
  export default value
}
