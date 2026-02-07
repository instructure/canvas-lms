/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import type {DiscoveryPageIcon} from './types'

// TODO: S3 bucket base URL
const ICON_BASE_URL = 'http://localhost:9000/icons'

export const getDiscoveryPageIcons = (): DiscoveryPageIcon[] => [
  {id: 'default', name: 'Default', url: `${ICON_BASE_URL}/default.svg`},
  {id: 'apple', name: 'Apple', url: `${ICON_BASE_URL}/apple.svg`},
  {id: 'auth0', name: 'Auth0', url: `${ICON_BASE_URL}/auth0.svg`},
  {id: 'classlink', name: 'ClassLink', url: `${ICON_BASE_URL}/classlink.svg`},
  {id: 'facebook', name: 'Facebook', url: `${ICON_BASE_URL}/facebook.svg`},
  {id: 'github', name: 'GitHub', url: `${ICON_BASE_URL}/github.svg`},
  {id: 'google', name: 'Google', url: `${ICON_BASE_URL}/google.svg`},
  {id: 'linkedin', name: 'LinkedIn', url: `${ICON_BASE_URL}/linkedin.svg`},
  {id: 'microsoft', name: 'Microsoft', url: `${ICON_BASE_URL}/microsoft.svg`},
  {id: 'okta', name: 'Okta', url: `${ICON_BASE_URL}/okta.svg`},
  {id: 'onelogin', name: 'OneLogin', url: `${ICON_BASE_URL}/onelogin.svg`},
  {id: 'ping', name: 'Ping', url: `${ICON_BASE_URL}/ping.svg`},
]
