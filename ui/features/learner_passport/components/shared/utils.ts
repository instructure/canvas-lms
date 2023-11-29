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

export function stringToId(s: string): string {
  return s.replace(/\W+/g, '-')
}

type hasFromToDates = {
  from_date: string
  to_date: string
}

export function compareFromToDates(a: hasFromToDates, b: hasFromToDates) {
  if (a.from_date < b.from_date) {
    return 1
  }
  if (a.from_date > b.from_date) {
    return -1
  }
  return 0
}

export const formatDate = (date: string | Date) => {
  return new Intl.DateTimeFormat(ENV.LOCALE || 'en', {month: 'short', year: 'numeric'}).format(
    new Date(date)
  )
}

export function isUrlToLocalCanvasFile(url: string): boolean {
  const fileURL = new URL(url, window.location.origin)

  const matchesCanvasFile = /(?:\/(courses|groups|users)\/(\d+))?\/files\/(\d+)/.test(
    fileURL.pathname
  )

  return matchesCanvasFile && fileURL.origin === window.location.origin
}
