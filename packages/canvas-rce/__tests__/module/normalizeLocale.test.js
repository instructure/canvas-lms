/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import normalizeLocale from '../../src/rce/normalizeLocale'

describe('normalizeLocale', () => {
  it("returns 'en' for null/undefined", () => {
    expect(normalizeLocale(null)).toEqual('en')
    expect(normalizeLocale(undefined)).toEqual('en')
  })

  it('maps unknown region locale to the base locale', () => {
    expect(normalizeLocale('he-IL')).toEqual('he')
  })

  it('maps known substitutions', () => {
    expect(normalizeLocale('fa')).toEqual('fa-IR')
  })

  it('reduces unrecognized custom locales to the base locale', () => {
    expect(normalizeLocale('en-GB-x-bogus')).toEqual('en-GB')
  })

  it("recognizes known custom locales and doesn't reduce them", () => {
    expect(normalizeLocale('en-GB-x-ukhe')).toEqual('en-GB-x-ukhe')
  })

  it('otherwise just return en', () => {
    expect(normalizeLocale('some-locale')).toEqual('en')
  })
})
