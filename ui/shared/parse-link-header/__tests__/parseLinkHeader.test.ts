/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import parseLinkHeader from '../parseLinkHeader'

const linkHeader =
  '<https://www.example.com/path?page=2&per_page=10>; rel="next", ' +
  '<https://www.example.com/path?page=1&per_page=10>; rel="prev"; foo="bar", ' +
  '<https://www.example.com/path?page=5&per_page=10>; rel="last"'

describe('parseLinkHeader', () => {
  it('should parse a link header', () => {
    const parsed = parseLinkHeader(linkHeader)
    expect(parsed).toEqual({
      next: {
        page: '2',
        per_page: '10',
        rel: 'next',
        url: 'https://www.example.com/path?page=2&per_page=10',
      },
      prev: {
        page: '1',
        per_page: '10',
        foo: 'bar',
        rel: 'prev',
        url: 'https://www.example.com/path?page=1&per_page=10',
      },
      last: {
        page: '5',
        per_page: '10',
        rel: 'last',
        url: 'https://www.example.com/path?page=5&per_page=10',
      },
    })
  })
})
