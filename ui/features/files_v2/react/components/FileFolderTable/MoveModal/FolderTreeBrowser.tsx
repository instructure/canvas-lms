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

import {forwardRef, useCallback, useImperativeHandle, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {TreeBrowser} from '@instructure/ui-tree-browser'
import {FormFieldMessage} from '@instructure/ui-form-field'
import {Collection, CollectionData} from '@instructure/ui-tree-browser/types/TreeBrowser/props'
import {View} from '@instructure/ui-view'
import {type Folder} from '../../../../interfaces/File'

type ApiFolderItem = {id: number; name: string}

type FolderCollection = Record<number | string, Collection>

type ApiFoldersResponse = ApiFolderItem[]

export type FolderTreeBrowserRef = {
  validate: () => boolean
}

type FolderTreeBrowserProps = {
  rootFolder: Folder
  onSelectFolder?: (folder: Collection | null) => void
}

const requestInnerFolders = (folderId: number | string) => {
  return doFetchApi<ApiFoldersResponse>({
    path: `/api/v1/folders/${folderId}/folders`,
  })
}

const parseFoldersResponse = (response: ApiFoldersResponse) =>
  response.reduce((result: FolderCollection, item: ApiFolderItem) => {
    result[item.id] = item
    return result
  }, {})

const I18n = createI18nScope('files_v2')

const FolderTreeBrowser = forwardRef<FolderTreeBrowserRef, FolderTreeBrowserProps>(
  ({rootFolder, onSelectFolder}, ref) => {
    const containerRef = useRef<Element | null>(null)
    const hasValidSelection = useRef<boolean>(false)
    const [loading, setLoading] = useState<boolean>(false)
    const [fetchError, setFetchError] = useState<Error | null>(null)
    const [formError, setFormError] = useState<string | null>(null)
    const [folders, setFolders] = useState<FolderCollection>({
      [rootFolder.id]: {id: rootFolder.id, name: rootFolder.name},
    })

    useImperativeHandle(ref, () => ({
      validate: () => {
        let valid = true
        if (!hasValidSelection.current) {
          valid = false
          setFormError(I18n.t('A target folder should be selected.'))
        }
        if (!valid && containerRef.current) {
          const treeElement = containerRef.current.querySelector('ul[role="tree"]')
          if (treeElement) (treeElement as HTMLUListElement).focus()
        }
        return valid
      },
    }))

    const updateSubFolders = useCallback(
      (response: ApiFoldersResponse, folder: Collection) => {
        const parsedFolders = parseFoldersResponse(response)
        const collections = Object.keys(parsedFolders).map(key => parsedFolders[key].id)
        const newFolders = Object.assign({}, folders, {
          [folder.id]: {...folder, collections},
          ...parsedFolders,
        })
        setFolders(newFolders)
      },
      [folders],
    )

    const updateRootSubFolders = useCallback((response: ApiFoldersResponse) => {
      const rootCollection = Object.assign({}, folders[rootFolder.id])
      updateSubFolders(response, rootCollection)
      // eslint-disable-next-line react-compiler/react-compiler
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [])

    const handleCollectionToggle = useCallback(
      (collection: CollectionData) => {
        setFormError(null)
        if (!collection.id) return

        const folder = Object.assign({}, folders[collection.id])
        if (!collection.expanded || folder.collections) return

        requestInnerFolders(folder.id)
          .then(response => response.json)
          .then(response => {
            if (!response) return
            updateSubFolders(response, folder)
          })
          .catch(setFetchError)
      },
      [folders, updateSubFolders],
    )

    const handleCollectionClick = useCallback(
      (_e: React.MouseEvent, data: CollectionData) => {
        setFormError(null)
        if (!data) return

        let folder = null
        if (data.id) folder = folders[data.id] || null
        onSelectFolder?.(folder)
        hasValidSelection.current = !!folder
      },
      [folders, onSelectFolder],
    )

    useFetchApi<ApiFoldersResponse, ApiFoldersResponse>({
      path: `/api/v1/folders/${rootFolder.id}/folders`,
      success: updateRootSubFolders,
      error: setFetchError,
      loading: setLoading,
    })

    if (loading) {
      return (
        <View as="div" textAlign="center">
          <Spinner size="small" renderTitle={I18n.t('Loading folders...')} />
        </View>
      )
    }

    return (
      <>
        {fetchError && (
          <Alert variant="error" renderCloseButtonLabel={I18n.t('Close error message')}>
            {I18n.t('An error occurred while fetching the folders.')}
          </Alert>
        )}
        <View elementRef={(element: Element | null) => (containerRef.current = element)}>
          <TreeBrowser
            size="medium"
            selectionType="single"
            collections={folders}
            items={{}}
            rootId={rootFolder.id}
            defaultExpanded={[rootFolder.id]}
            onCollectionToggle={handleCollectionToggle}
            onCollectionClick={handleCollectionClick}
          />
        </View>
        {formError && (
          <View as="div" margin="x-small none none none">
            <FormFieldMessage variant="newError">{formError}</FormFieldMessage>
          </View>
        )}
      </>
    )
  },
)

export default FolderTreeBrowser
