/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {createBrowserRouter, Outlet, RouteObject} from 'react-router-dom'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import {FilesGenericErrorPage} from '../react/components/FilesGenericErrorPage'
import AllMyFilesTable from '../react/components/AllMyFilesTable'
import FilesApp from '../react/components/FilesApp'

const ROUTES = {
  ALL_FOLDER: 'folder/:context/*',
  FOLDER: 'folder/*',
} as const

const allMyFilesRoutes: RouteObject[] = [
  {
    index: true,
    Component: AllMyFilesTable,
  },
  {
    path: ROUTES.ALL_FOLDER,
    Component: FilesApp,
  },
]

const filesRoutes: RouteObject[] = [
  {
    index: true,
    Component: FilesApp,
  },
  {
    path: ROUTES.FOLDER,
    Component: FilesApp,
  },
]

const routes: RouteObject[] = [
  {
    path: '/',
    errorElement: <FilesGenericErrorPage />,
    Component: Outlet,
    children: filesEnv.showingAllContexts
      ? allMyFilesRoutes
      : filesRoutes
  }
]

export const router = createBrowserRouter(routes, {
  basename: filesEnv.baseUrl,
})
