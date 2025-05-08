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
import {getFilesEnv} from '../utils/filesEnvUtils'
import AllMyFilesTable from '../react/components/AllMyFilesTable'
import FilesApp from '../react/components/FilesApp'
import {ReThrowRouteError} from './ReThrowRouteError'

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
    // react-router does not support skipping its own error handling
    // ref: https://github.com/remix-run/react-router/discussions/10166
    errorElement: <ReThrowRouteError />,
    Component: Outlet,
    children: getFilesEnv().showingAllContexts ? allMyFilesRoutes : filesRoutes,
  },
]

export const router = createBrowserRouter(routes, {
  basename: getFilesEnv().baseUrl,
})
