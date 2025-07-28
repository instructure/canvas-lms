/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

export const instructorAppsRoute = window.location.pathname.includes('configurations')
  ? 'configurations'
  : 'settings'

export const instructorAppsHash = '#tab-apps'

export const productRoute = (globalProductId: string) => {
  const accountId = ENV.ACCOUNT_ID
  const pathname = window.location.pathname.includes(instructorAppsRoute)
    ? `/courses/${accountId}/settings`
    : `/accounts/${accountId}/apps`
  return `${window.location.origin}${pathname}/product_detail/${globalProductId}${
    window.location.pathname.includes(instructorAppsRoute) ? instructorAppsHash : ''
  }`
}
