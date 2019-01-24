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

import sanitizeUrl from "../sanitizeUrl";

it('removes replaces javascript: scheme urls with about:blank', () => {
  // eslint-disable-next-line no-script-url
  expect(sanitizeUrl('javascript:prompt(document.cookie);prompt(document.domain);')).toBe('about:blank')
})

it('leaves normal non-javascript: urls alone', () => {
  expect(sanitizeUrl('http://instructure.com')).toBe('http://instructure.com')
})

