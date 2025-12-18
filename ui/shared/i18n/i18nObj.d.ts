/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

/**
 * A scoped I18n instance for a specific feature/component.
 *
 * Common usage patterns:
 * - I18n.t('Hello') - simple string
 * - I18n.t('Hello %{name}', {name: 'World'}) - with interpolation
 * - I18n.t({one: '1 item', other: '%{count} items'}, {count: 5}) - pluralization
 * - I18n.t('#key.path') - translation key lookup
 * - I18n.l('#date.formats.medium', date) - localize date/number
 */
export class Scope {
  /** Translate a string with optional interpolation or pluralization */
  t(key: string | Record<string, string>, ...args: unknown[]): string

  /** Alias for t() */
  translate(key: string | Record<string, string>, ...args: unknown[]): string

  /** Localize a value (date, number, etc.) */
  l(format: string, value: unknown): string

  /** Format a number */
  n(value: number, options?: unknown): string

  /** Pluralize a string */
  p(count: number, key: string, options?: unknown): string

  /** Get the current locale */
  currentLocale(): string

  /** Format a number as a percentage */
  toPercentage(value: number, options?: unknown): string

  /** Look up a translation key */
  lookup(key: string, options?: unknown): string | null

  /** Allow additional properties for extensibility */
  [key: string]: unknown
}

/** Create a scoped I18n instance for a feature */
export function useScope(scope: string): Scope

/** Register translations for a locale */
export function registerTranslations(locale: string, translations: unknown): void

/** Use translations for a locale */
export function useTranslations(locale: string, translations: unknown): void

/** Global I18n object */
declare const I18n: Scope & {
  scoped: typeof useScope
  registerTranslations: typeof registerTranslations
}

export default I18n
