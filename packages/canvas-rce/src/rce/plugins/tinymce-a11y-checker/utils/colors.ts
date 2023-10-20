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

type Color = {
  r: number
  g: number
  b: number
  a: number
}

export function stringifyRGBA(rgba: Color): string {
  return `rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${rgba.a})`
}

export function parseRGBA(rgba: string): Color | null {
  try {
    const tokens = rgba.slice(5, -1).split(',')
    if (tokens.length !== 4) throw new Error('Invalid color')
    const [r, g, b, a] = tokens.map(n => Number(n.trim()) || 0)
    return {r, g, b, a}
  } catch (e) {
    return null
  }
}

export function restrictColorValues(rgba: Color): Color {
  return {
    r: Math.max(Math.min(rgba.r, 255), 0),
    g: Math.max(Math.min(rgba.g, 255), 0),
    b: Math.max(Math.min(rgba.b, 255), 0),
    a: Math.max(Math.min(rgba.a, 1), 0),
  }
}
