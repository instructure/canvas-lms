/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export const MOCK_OBSERVED_USERS_LIST = [
  {
    id: '13',
    name: 'Zelda',
    avatar_url: 'http://avatar',
  },
  {
    id: '4',
    name: 'Student 4',
    avatar_url: 'http://canvas.instructure.com/images/messages/avatar-50.png',
  },
  {
    id: '2',
    name: 'Student 2',
    avatar_url:
      'http://localhost:3000/images/thumbnails/424/pLccjAlvK1xtbcCRgvSMElUOwCBnFU26kgXRif8h',
  },
  {
    id: '5',
    name: 'Student 5',
    avatar_url: 'http://canvas.instructure.com/images/messages/avatar-50.png',
  },
]

export const SHOW_K5_DASHBOARD_ROUTE = /\/api\/v1\/show_k5_dashboard/
export const showK5DashboardResponse = (k5User = true, useClassicFont = false) => ({
  show_k5_dashboard: k5User,
  use_classic_font: useClassicFont,
})
