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

export type UserOS = 'Mac' | 'Windows' | 'Other'

export type OSKey = 'OPTION' | 'ALT'

export const determineUserOS = (): UserOS => {
  const rawOS = navigator.userAgent
  if (rawOS.indexOf('Mac') !== -1) return 'Mac'
  else if (rawOS.indexOf('Win') !== -1) return 'Windows'
  else return 'Other'
}

export const determineOSDependentKey = (): OSKey => {
  switch (determineUserOS()) {
    case 'Mac':
      return 'OPTION'
    case 'Windows':
    default:
      return 'ALT'
  }
}
