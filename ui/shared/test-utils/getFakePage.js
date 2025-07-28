/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

// helper to get a fake page from the "server", gives you some fake model data
// and the Link header, don't send it a page greater than 10 or less than 1
export default function getFakePage(thisPage = 1) {
  const url = page => `/api/v1/context/2/resource?page=${page}&per_page=2`
  const lastID = thisPage * 2
  const urls = {
    current: url(thisPage),
    first: url(1),
    last: url(10),
  }
  const links = [`<${urls.current}>; rel="current"`]
  if (thisPage < 10) {
    urls.next = url(thisPage + 1)
    links.push(`<${urls.next}>; rel="next"`)
  }
  if (thisPage > 1) {
    urls.prev = url(thisPage - 1)
    links.push(`<${urls.prev}>; rel="prev"`)
  }
  links.push(`<${urls.first}>; rel="first"`)
  links.push(`<${urls.last}>; rel="last"`)
  return {
    urls,
    header: links.join(','),
    data: [
      {id: lastID - 1, foo: 'bar', baz: 'qux'},
      {id: lastID, foo: 'bar', baz: 'qux'},
    ],
  }
}
