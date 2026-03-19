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

import defaultIcon from './images/default.svg'
import appleIcon from './images/apple.svg'
import auth0Icon from './images/auth0.svg'
import classlinkIcon from './images/classlink.svg'
import facebookIcon from './images/facebook.svg'
import githubIcon from './images/github.svg'
import googleIcon from './images/google.svg'
import linkedinIcon from './images/linkedin.svg'
import microsoftIcon from './images/microsoft.svg'
import oktaIcon from './images/okta.svg'
import oneloginIcon from './images/onelogin.svg'
import pingIcon from './images/ping.svg'

export const DISCOVERY_PAGE_ICONS: DiscoveryPageIcon[] = [
  {id: 'default', name: 'Default', url: defaultIcon},
  {id: 'apple', name: 'Apple', url: appleIcon},
  {id: 'auth0', name: 'Auth0', url: auth0Icon},
  {id: 'classlink', name: 'ClassLink', url: classlinkIcon},
  {id: 'facebook', name: 'Facebook', url: facebookIcon},
  {id: 'github', name: 'GitHub', url: githubIcon},
  {id: 'google', name: 'Google', url: googleIcon},
  {id: 'linkedin', name: 'LinkedIn', url: linkedinIcon},
  {id: 'microsoft', name: 'Microsoft', url: microsoftIcon},
  {id: 'okta', name: 'Okta', url: oktaIcon},
  {id: 'onelogin', name: 'OneLogin', url: oneloginIcon},
  {id: 'ping', name: 'Ping', url: pingIcon},
]
