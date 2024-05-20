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

import React from 'react'
import ReactDOM from 'react-dom'
import {createBrowserRouter, RouterProvider, Link} from 'react-router-dom'
import {Discover} from './discover/components/Discover'
import {Manage} from './manage/Manage'
import {LtiAppsLayout} from './layout/LtiAppsLayout'
import {DiscoverRoute} from './discover/components'
import {ManageRoute} from './manage'

const getBasename = () => {
  const path = window.location.pathname
  const parts = path.split('/')
  return parts.slice(0, parts.indexOf('extensions') + 1).join('/')
}

// window.ENV.lti_registrations_discover_page

const router = createBrowserRouter(
  [
    {
      path: '/',
      element: <LtiAppsLayout />,
      children: window.ENV.FEATURES.lti_registrations_discover_page
        ? [DiscoverRoute, ManageRoute]
        : [ManageRoute],
    },
  ],
  {
    basename: getBasename(),
  }
)

ReactDOM.render(<RouterProvider router={router} />, document.getElementById('reactContent'))
