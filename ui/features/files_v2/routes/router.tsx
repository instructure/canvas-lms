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

import {createBrowserRouter, Outlet, LoaderFunctionArgs} from 'react-router-dom'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {useScope as createI18nScope} from '@canvas/i18n'
import FilesApp from '../react/components/FilesApp'
import {generateFolderByPathUrl} from '../utils/apiUtils'
import AllMyFilesTable from '../react/components/AllMyFilesTable'
import {createStubRootFolder} from '../utils/folderUtils'
import {LoaderData} from '../interfaces/LoaderData'

const contextAssetString = window.ENV.context_asset_string
const showingAllContexts = filesEnv.showingAllContexts
const I18n = createI18nScope('files_v2')

const routes = [
  {
    path: '/',
    errorElement: (
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={I18n.t('Files Index initial query error')}
            errorCategory={I18n.t('Files Index Error Page')}
          />
        }
      ></ErrorBoundary>
    ),
    element: <Outlet />,
    children: [
      {
        index: true,
        element: showingAllContexts ? (
          <AllMyFilesTable />
        ) : (
          <FilesApp contextAssetString={contextAssetString} />
        ),
        loader: (): LoaderData | null => {
          if (showingAllContexts) return null
          const context = filesEnv.contexts[0]
          const rootFolder = createStubRootFolder(context)
          return {folders: [rootFolder], searchTerm: ''}
        },
      },
      {
        path: 'folder?/:pluralContext?/search',
        element: <FilesApp contextAssetString={contextAssetString} />,
        loader: async ({params, request}: LoaderFunctionArgs): Promise<LoaderData> => {
          const searchTerm = new URL(request.url).searchParams.get('search_term') || ''
          let context
          if (params.pluralContext) {
            const [pluralContextType, contextId] = params.pluralContext.split('_')
            context = filesEnv.contextsDictionary[`${pluralContextType}_${contextId}`]
          } else {
            context = filesEnv.contexts[0]
          }
          return {folders: [createStubRootFolder(context)], searchTerm}
        },
      },
      {
        path: 'folder/:folderPathOrPluralContext?/*',
        element: <FilesApp contextAssetString={contextAssetString} />,
        loader: async ({params}: LoaderFunctionArgs): Promise<LoaderData> => {
          if (filesEnv.showingAllContexts && !params['*']) {
            const [pluralContextType, contextId] =
              params.folderPathOrPluralContext?.split('_') || []
            const context = filesEnv.contextsDictionary[`${pluralContextType}_${contextId}`]
            return {folders: [createStubRootFolder(context)], searchTerm: ''}
          }

          if (!filesEnv.showingAllContexts && !params.folderPathOrPluralContext) {
            const context = filesEnv.contexts[0]
            return {folders: [createStubRootFolder(context)], searchTerm: ''}
          }

          const path = params['*']
            ? `${params.folderPathOrPluralContext}/${params['*']}`
            : params.folderPathOrPluralContext

          const url = generateFolderByPathUrl(`/${path ?? ''}`)
          const resp = await fetch(url)
          const folders = await resp.json()
          if (!folders || folders.length === 0) {
            throw new Error('Error fetching by_path')
          }

          return {folders, searchTerm: ''}
        },
      },
    ],
  },
]

export const router = createBrowserRouter(routes, {
  basename: filesEnv.baseUrl,
})
