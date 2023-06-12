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

import sanitizeUrl from '../sanitizeUrl'

it('replaces javascript: scheme urls with about:blank', () => {
  // eslint-disable-next-line no-script-url
  expect(sanitizeUrl('javascript:prompt(document.cookie);prompt(document.domain);')).toBe(
    'about:blank'
  )
})

it('is not fooled by obfuscating the scheme with newlines and stuff', () => {
  expect(sanitizeUrl('javascri\npt:prompt(document.cookie);prompt(document.domain);')).toBe(
    'about:blank'
  )
})

it('is not hoodwinked by mixed-case tomfoolery', () => {
  // eslint-disable-next-line no-script-url
  expect(sanitizeUrl('jaVascripT:prompt(document.cookie);prompt(document.domain);')).toBe(
    'about:blank'
  )
})

it('leaves normal non-javascript: http urls alone', () => {
  expect(sanitizeUrl('http://instructure.com')).toBe('http://instructure.com')
})

it('leaves normal non-javascript: https urls alone', () => {
  expect(sanitizeUrl('https://instructure.com')).toBe('https://instructure.com')
})

it('leaves schemeless absolute urls alone', () => {
  expect(sanitizeUrl('/index.html')).toBe('/index.html')
})

it('leaves relative urls alone', () => {
  expect(sanitizeUrl('lolcats.gif')).toBe('lolcats.gif')
})

it('replaces totally invalid urls with about:blank', () => {
  expect(sanitizeUrl('https://#')).toBe('about:blank')
})
