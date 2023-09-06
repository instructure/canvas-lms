/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import validateURL from '../plugins/instructure_links/validateURL'

describe('validateURL', () => {
  it('accepts ftp URLs', () => {
    expect(validateURL('ftp://host:port/path')).toBe(true)
  })
  it('accepts http URLs', () => {
    expect(validateURL('http://host:port/path')).toBe(true)
  })
  it('accepts https URLs', () => {
    expect(validateURL('https://host:port/path')).toBe(true)
  })
  it('accepts mailto URLs', () => {
    expect(validateURL('mailto://you@address')).toBe(true)
    expect(validateURL('mailto:you@address')).toBe(true)
  })
  it('accepts skype URLs', () => {
    expect(validateURL('skype://participant1;participant2')).toBe(true)
    expect(validateURL('skype:participant1;participant2')).toBe(true)
  })
  it('accepts tel URLs', () => {
    // these are unusally short because the node `url` library in node >= 18.17.0 requires them to
    // be parseable as an IP address for some inexplicable reason.  The npm `url` library has no
    // such restriction but cannot be loaded in tests because `url` is a core module.
    expect(validateURL('tel://8005551')).toBe(true)
    expect(validateURL('tel:8005551')).toBe(true)
  })
  it('accepts no protocol', () => {
    expect(validateURL('//host:port/path')).toBe(true)
  })
  it('accepts path only', () => {
    expect(validateURL('/absolute_path')).toBe(true)
    expect(validateURL('relative_path')).toBe(true)
  })
  it('rejects an invalid protol', () => {
    expect(() => validateURL('xxx://host:port/path')).toThrow(/xxx is not a valid protocol./)
  })
  it('rejects : only protol', () => {
    expect(() => validateURL('://host:port/path')).toThrow(/Protocol must be ftp,/)
  })
  it('rejects ftp and http URLs with no slashed', () => {
    expect(() => validateURL('http:host')).toThrow(/Invalid URL/)
    expect(() => validateURL('https:host')).toThrow(/Invalid URL/)
    expect(() => validateURL('ftp:host')).toThrow(/Invalid URL/)
  })
  it('reserves judgement on partial URLs', () => {
    expect(validateURL('http:')).toBe(false)
    expect(validateURL('http:/')).toBe(false)
    expect(validateURL('http://')).toBe(false)
    expect(validateURL('http://x')).toBe(true)
    expect(validateURL('//')).toBe(false)
    expect(validateURL('mailto:')).toBe(false)
    expect(validateURL('mailto://')).toBe(false)
  })
})
