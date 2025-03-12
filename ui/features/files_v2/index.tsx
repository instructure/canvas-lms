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
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import FilesApp from './react/components/FilesApp'
import {createBrowserRouter, RouterProvider} from 'react-router-dom'
import {QueryProvider} from '@canvas/query'
import {createRoot} from 'react-dom/client'
import {generateFolderByPathUrl} from './utils/apiUtils'
import AllMyFilesTable from './react/components/AllMyFilesTable'
import {createStubRootFolder} from './utils/folderUtils'

const contextAssetString = window.ENV.context_asset_string
const showingAllContexts = filesEnv.showingAllContexts

const router = createBrowserRouter(
  [
    {
      path: '/folder/:pluralContext/search',
      element: <FilesApp contextAssetString={contextAssetString} />,
      loader: async ({params, request}) => {
        const searchTerm = new URL(request.url).searchParams.get('search_term')
        const [pluralContextType, contextId] = params['pluralContext']?.split('_') || []
        const context = filesEnv.contextsDictionary[`${pluralContextType}_${contextId}`]
        const rootFolder = createStubRootFolder(
          context.contextId,
          context.contextType,
          context.root_folder_id,
        )
        const folders = [rootFolder]
        return {folders: folders, searchTerm: searchTerm}
      },
    },
    {
      path: '/search',
      element: <FilesApp contextAssetString={contextAssetString} />,
      loader: async ({request}) => {
        const searchTerm = new URL(request.url).searchParams.get('search_term')
        const context = filesEnv.contexts[0]
        const rootFolder = createStubRootFolder(
          context.contextId,
          context.contextType,
          context.root_folder_id,
        )
        const folders = [rootFolder]
        return {folders: folders, searchTerm: searchTerm}
      },
    },
    {
      path: '/',
      element: showingAllContexts ? (
        <AllMyFilesTable />
      ) : (
        <FilesApp contextAssetString={contextAssetString} />
      ),
      loader: async () => {
        if (showingAllContexts) return null

        const context = filesEnv.contexts[0]
        const rootFolder = createStubRootFolder(
          context.contextId,
          context.contextType,
          context.root_folder_id,
        )
        const folders = [rootFolder]

        return {folders: folders, searchTerm: ''}
      },
    },
    {
      path: '/folder/:pluralContextOrFolder',
      element: <FilesApp contextAssetString={contextAssetString} />,
      loader: async ({params}) => {
        let folders
        if (filesEnv.showingAllContexts) {
          // files/folder/users_1
          const [pluralContextType, contextId] = params['pluralContextOrFolder']?.split('_') || []
          const context = filesEnv.contextsDictionary[`${pluralContextType}_${contextId}`]
          const folder = createStubRootFolder(
            context.contextId,
            context.contextType,
            context.root_folder_id,
          )
          folders = [folder]
        } else {
          // files/folder/some_folder
          const url = generateFolderByPathUrl(`/${params['pluralContextOrFolder']}`)
          const resp = await fetch(url)
          folders = await resp.json()
        }
        return {folders: folders, searchTerm: ''}
      },
    },
    {
      path: '/folder/*',
      element: <FilesApp contextAssetString={contextAssetString} />,
      loader: async ({params}) => {
        const url = generateFolderByPathUrl(`/${params['*']}`)
        const resp = await fetch(url)
        const folders = await resp.json()

        return {folders: folders, searchTerm: ''}
      },
    },
  ],
  {
    basename: filesEnv.baseUrl,
  },
)

const root = createRoot(document.getElementById('content')!)

root.render(
  <QueryProvider>
    <RouterProvider router={router} />
  </QueryProvider>,
)
